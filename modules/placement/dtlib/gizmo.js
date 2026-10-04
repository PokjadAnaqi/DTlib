// DTlib native entity gizmo runtime.
// v1.0.27 keeps the proven v1.0.6 direct DrawGizmo entity path and adds
// a separate object-orbit camera interaction. Gizmo transforms remain direct 1:1;
// LMB drag on empty space orbits the camera around the object and wheel zooms.

let session = null;
let sequence = 0;
let pauseGuardUntil = 0;
let deferredCursorExit = false;

const CURSOR_NORMAL = 1;
const CURSOR_GRAB = 3;
const CURSOR_GRABBING = 4;

const ORBIT_DEFAULTS = {
    minRadius: 1.5,
    maxRadius: 25.0,
    zoomStep: 0.75,
    sensitivity: 0.005,
    blend: 250,
    dragThresholdPx: 4.0,
};

function vec3(v) {
    if (!v) return { x: 0.0, y: 0.0, z: 0.0 };
    return { x: Number(v[0] ?? v.x ?? 0.0), y: Number(v[1] ?? v.y ?? 0.0), z: Number(v[2] ?? v.z ?? 0.0) };
}

function length3(x, y, z) {
    return Math.sqrt((x * x) + (y * y) + (z * z));
}

function normaliseAxis(x, y, z, fallback) {
    const len = length3(x, y, z);
    if (len < 0.00001) return fallback;
    return [x / len, y / len, z / len];
}

function makeEntityMatrix(entity) {
    const [forward, right, up, at] = GetEntityMatrix(entity);
    return new Float32Array([
        right[0], right[1], right[2], 0.0,
        forward[0], forward[1], forward[2], 0.0,
        up[0], up[1], up[2], 0.0,
        at[0], at[1], at[2], 1.0,
    ]);
}

function applyEntityMatrix(entity, matrix, allowScale) {
    let rx = matrix[0], ry = matrix[1], rz = matrix[2];
    let fx = matrix[4], fy = matrix[5], fz = matrix[6];
    let ux = matrix[8], uy = matrix[9], uz = matrix[10];

    if (!allowScale) {
        [rx, ry, rz] = normaliseAxis(rx, ry, rz, [1.0, 0.0, 0.0]);
        [fx, fy, fz] = normaliseAxis(fx, fy, fz, [0.0, 1.0, 0.0]);
        [ux, uy, uz] = normaliseAxis(ux, uy, uz, [0.0, 0.0, 1.0]);
    }

    SetEntityMatrix(
        entity,
        fx, fy, fz,
        rx, ry, rz,
        ux, uy, uz,
        matrix[12], matrix[13], matrix[14]
    );
}

function snapshot(entity) {
    const coords = GetEntityCoords(entity, false);
    const rotation = GetEntityRotation(entity, 2);
    return {
        matrix: makeEntityMatrix(entity),
        coords: vec3(coords),
        rotation: vec3(rotation),
        heading: Number(GetEntityHeading(entity) || 0.0),
    };
}

function resultPayload(active, confirmed, cancelled, reason) {
    const entity = active.entity;
    const exists = DoesEntityExist(entity);
    const coords = exists ? vec3(GetEntityCoords(entity, false)) : active.snapshot.coords;
    const rotation = exists ? vec3(GetEntityRotation(entity, 2)) : active.snapshot.rotation;

    return {
        id: active.id,
        entity,
        confirmed: !!confirmed,
        cancelled: !!cancelled,
        reason: reason || null,
        coords,
        position: coords,
        rotation,
        heading: exists ? Number(GetEntityHeading(entity) || 0.0) : active.snapshot.heading,
        limited: !!active.limited,
    };
}

function restore(active) {
    if (!DoesEntityExist(active.entity)) return;
    applyEntityMatrix(active.entity, active.snapshot.matrix, true);
}

function setPlacementCursor(active) {
    if (!active) return;
    try {
        SetMouseCursorActiveThisFrame();
        if (active.cameraDragging) {
            SetMouseCursorSprite(CURSOR_GRABBING);
        } else if (active.pointerDown && active.gizmoChangedSincePress) {
            // Let the direct gizmo drag retain a neutral cursor while an axis is active.
            SetMouseCursorSprite(CURSOR_NORMAL);
        } else {
            SetMouseCursorSprite(CURSOR_GRAB);
        }
    } catch (_) {}
}

function resetCursor() {
    try { SetMouseCursorSprite(CURSOR_NORMAL); } catch (_) {}
}

function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
}

function cursorPosition() {
    return {
        x: Number(GetDisabledControlNormal(0, 239) || GetControlNormal(0, 239) || 0.5),
        y: Number(GetDisabledControlNormal(0, 240) || GetControlNormal(0, 240) || 0.5),
    };
}

function screenResolution() {
    try {
        const result = GetActiveScreenResolution();
        if (Array.isArray(result)) return { x: Number(result[0] || 1920), y: Number(result[1] || 1080) };
    } catch (_) {}
    return { x: 1920, y: 1080 };
}

function entityPivot(entity) {
    const origin = vec3(GetEntityCoords(entity, false));
    try {
        const dims = GetModelDimensions(GetEntityModel(entity));
        if (Array.isArray(dims) && dims.length >= 2) {
            const min = vec3(dims[0]);
            const max = vec3(dims[1]);
            const center = {
                x: (min.x + max.x) * 0.5,
                y: (min.y + max.y) * 0.5,
                z: (min.z + max.z) * 0.5,
            };
            return vec3(GetOffsetFromEntityInWorldCoords(entity, center.x, center.y, center.z));
        }
    } catch (_) {}
    return origin;
}

function orbitOptions(active) {
    const orbit = active.options.orbit || {};
    return {
        minRadius: Number(orbit.minRadius ?? active.options.cameraMinDistance ?? ORBIT_DEFAULTS.minRadius),
        maxRadius: Number(orbit.maxRadius ?? active.options.cameraMaxDistance ?? ORBIT_DEFAULTS.maxRadius),
        zoomStep: Number(orbit.zoomStep ?? active.options.cameraZoomStep ?? ORBIT_DEFAULTS.zoomStep),
        sensitivity: Number(orbit.sensitivity ?? active.options.cameraSensitivity ?? ORBIT_DEFAULTS.sensitivity),
        blend: Number(orbit.blend ?? ORBIT_DEFAULTS.blend),
        dragThresholdPx: Number(orbit.dragThresholdPx ?? ORBIT_DEFAULTS.dragThresholdPx),
    };
}

function ensureOrbitCamera(active) {
    if (active.cam && DoesCamExist(active.cam)) return;

    const cfg = orbitOptions(active);
    const target = entityPivot(active.entity);
    const camPos = vec3(GetFinalRenderedCamCoord());
    const dx = camPos.x - target.x;
    const dy = camPos.y - target.y;
    const dz = camPos.z - target.z;
    let radius = length3(dx, dy, dz);
    if (radius < 0.001) radius = 3.0;
    radius = clamp(radius, cfg.minRadius, cfg.maxRadius);

    active.camTarget = target;
    active.radius = radius;
    active.theta = Math.atan2(dy, dx);
    active.phi = Math.acos(clamp(dz / radius, -1.0, 1.0));
    active.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true);
    SetCamFov(active.cam, Number(GetFinalRenderedCamFov() || 50.0));
    RenderScriptCams(true, true, cfg.blend, true, true);
}

function destroyOrbitCamera(active) {
    if (!active || !active.cam) return;
    const cam = active.cam;
    const cfg = orbitOptions(active);
    active.cam = 0;
    RenderScriptCams(false, true, cfg.blend, true, true);
    setTimeout(() => {
        try { if (DoesCamExist(cam)) DestroyCam(cam, false); } catch (_) {}
    }, Math.max(0, cfg.blend));
}

function updateOrbitCamera(active) {
    if (!active.cam || !DoesCamExist(active.cam)) return;

    const pivot = entityPivot(active.entity);
    if (!active.gizmoDragging) {
        if (!active.camTarget) active.camTarget = pivot;
        active.camTarget = {
            x: active.camTarget.x + ((pivot.x - active.camTarget.x) * 0.18),
            y: active.camTarget.y + ((pivot.y - active.camTarget.y) * 0.18),
            z: active.camTarget.z + ((pivot.z - active.camTarget.z) * 0.18),
        };
    }

    const sinPhi = Math.sin(active.phi);
    const position = {
        x: active.camTarget.x + (active.radius * sinPhi * Math.cos(active.theta)),
        y: active.camTarget.y + (active.radius * sinPhi * Math.sin(active.theta)),
        z: active.camTarget.z + (active.radius * Math.cos(active.phi)),
    };

    SetCamCoord(active.cam, position.x, position.y, position.z);
    PointCamAtCoord(active.cam, active.camTarget.x, active.camTarget.y, active.camTarget.z);
}

function beginCameraDrag(active, current) {
    if (active.cameraDragging || active.options.camera === 'gameplay' || active.options.cameraMode === 'gameplay') return;
    ensureOrbitCamera(active);
    active.cameraDragging = true;
    active.lastCursor = current;
    // Release Cfx gizmo selection only after DrawGizmo had a chance to claim the
    // press. Empty-space drags become camera orbit; axis drags stay untouched.
    ExecuteCommand('-gizmoSelect');
}

function handleOrbitInput(active) {
    if (active.options.camera === 'gameplay' || active.options.cameraMode === 'gameplay') return;

    const cfg = orbitOptions(active);
    const current = cursorPosition();
    const res = screenResolution();

    if (active.pointerDown) {
        const fromPressX = (current.x - active.pressCursor.x) * res.x;
        const fromPressY = (current.y - active.pressCursor.y) * res.y;
        const totalMove = Math.sqrt((fromPressX * fromPressX) + (fromPressY * fromPressY));

        if (!active.cameraDragging && !active.gizmoChangedSincePress && totalMove >= cfg.dragThresholdPx) {
            beginCameraDrag(active, current);
        }

        if (active.cameraDragging) {
            const dx = (current.x - active.lastCursor.x) * res.x;
            const dy = (current.y - active.lastCursor.y) * res.y;
            active.theta -= dx * cfg.sensitivity;
            active.phi = clamp(active.phi - (dy * cfg.sensitivity), 0.12, Math.PI - 0.12);
            active.lastCursor = current;
        }
    }

    // FiveM cursor-mode wheel input is exposed through frontend wheel controls
    // 14/15 on many builds, while 241/242 are the cursor-scroll controls. Read
    // both paths, but apply only one zoom step per frame.
    const zoomOut = IsDisabledControlJustReleased(0, 14) || IsControlJustReleased(0, 14);
    const zoomIn = IsDisabledControlJustReleased(0, 15) || IsControlJustReleased(0, 15);
    const cursorScrollUp = IsDisabledControlJustPressed(0, 241) || IsControlJustPressed(0, 241);
    const cursorScrollDown = IsDisabledControlJustPressed(0, 242) || IsControlJustPressed(0, 242);
    if (zoomOut || zoomIn || cursorScrollUp || cursorScrollDown) {
        ensureOrbitCamera(active);
        const direction = (zoomOut || cursorScrollDown) ? 1.0 : -1.0;
        active.radius = clamp(
            active.radius + (direction * cfg.zoomStep),
            cfg.minRadius,
            cfg.maxRadius
        );
        updateOrbitCamera(active);
    }

    updateOrbitCamera(active);
}

function releaseGizmoControls(active, deferCursorExit = false) {
    ExecuteCommand('-gizmoSelect');
    ExecuteCommand('-gizmoTranslation');
    ExecuteCommand('-gizmoRotation');
    ExecuteCommand('-gizmoScale');
    ExecuteCommand('-gizmoLocal');
    destroyOrbitCamera(active);
    restoreFrozenPeds(active);
    resetCursor();
    if (active && active.cursorEntered) {
        if (deferCursorExit) {
            // Do not leave cursor mode while ESC is still down. FiveM can open
            // the pause frontend during that transition even when the same frame
            // consumed INPUT_FRONTEND_PAUSE.
            deferredCursorExit = true;
        } else {
            LeaveCursorMode();
            active.cursorEntered = false;
        }
    }
}

function finish(cancelled, reason) {
    if (!session) return;
    const active = session;
    session = null;

    if (cancelled) {
        // ESC is also GTA's pause/back input. Keep it consumed until released.
        pauseGuardUntil = GetGameTimer() + 350;
    }

    releaseGizmoControls(active, cancelled);

    if (cancelled && active.options.restoreOnCancel !== false) {
        restore(active);
    }

    if (DoesEntityExist(active.entity)) {
        SetEntityDrawOutline(active.entity, false);
    }

    emit('DTlib:gizmo:result', active.id, resultPayload(active, !cancelled, cancelled, reason));
}

function clampDistance(active) {
    const limit = Number(active.options.distanceLimit || 0.0);
    if (!(limit > 0.0) || !DoesEntityExist(active.entity)) {
        active.limited = false;
        return;
    }

    const coords = vec3(GetEntityCoords(active.entity, false));
    const origin = active.origin;
    const dx = coords.x - origin.x;
    const dy = coords.y - origin.y;
    const dz = coords.z - origin.z;
    const distance = length3(dx, dy, dz);

    if (distance <= limit || distance < 0.00001) {
        active.limited = false;
        return;
    }

    const scale = limit / distance;
    SetEntityCoordsNoOffset(
        active.entity,
        origin.x + (dx * scale),
        origin.y + (dy * scale),
        origin.z + (dz * scale),
        false, false, false
    );
    active.limited = true;
}

function pushChange(active) {
    const now = GetGameTimer();
    const throttle = Number(active.options.changeInterval || 75);
    if (now - active.lastChange < throttle) return;
    active.lastChange = now;
    emit('DTlib:gizmo:change', active.id, resultPayload(active, false, false, 'changed'));
}

function rememberFrozenPed(active, ped) {
    if (!active || !ped || !DoesEntityExist(ped)) return;
    if (!active.frozenPeds) active.frozenPeds = new Map();
    if (!active.frozenPeds.has(ped)) {
        let wasFrozen = false;
        try { wasFrozen = !!IsEntityPositionFrozen(ped); } catch (_) {}
        active.frozenPeds.set(ped, wasFrozen);
    }
}

function restoreFrozenPeds(active) {
    if (!active) return;

    if (active.frozenPeds) {
        for (const [ped, wasFrozen] of active.frozenPeds.entries()) {
            try {
                if (!DoesEntityExist(ped)) continue;
                FreezeEntityPosition(ped, wasFrozen === true);
                if (wasFrozen !== true) SetEntityVelocity(ped, 0.0, 0.0, 0.0);
            } catch (_) {}
        }
        active.frozenPeds.clear();
    }

    if (active.options && active.options.freezePlayer !== false) {
        try {
            const currentPed = PlayerPedId();
            if (currentPed && DoesEntityExist(currentPed) && currentPed !== active.playerPed) {
                FreezeEntityPosition(currentPed, false);
                SetEntityVelocity(currentPed, 0.0, 0.0, 0.0);
            }
        } catch (_) {}
    }
}

function disableGameplay(active) {
    if (active.options.blockInput === false) return;

    // Full PED/gameplay input lock. Gizmo commands are registered key mappings
    // and camera/zoom reads disabled controls, so all GTA control groups can be
    // disabled without leaking LMB/RMB or keyboard actions to the player PED.
    for (let pad = 0; pad <= 2; pad += 1) {
        DisableAllControlActions(pad);
    }

    SetPauseMenuActive(false);
    DisablePlayerFiring(PlayerId(), true);

    if (active.options.freezePlayer !== false) {
        const ped = PlayerPedId();
        if (ped && DoesEntityExist(ped)) {
            rememberFrozenPed(active, ped);
            FreezeEntityPosition(ped, true);
            SetEntityVelocity(ped, 0.0, 0.0, 0.0);
            ClearPedSecondaryTask(ped);

            if (IsPedInMeleeCombat(ped) || IsPedShooting(ped) || IsPedReloading(ped)) {
                ClearPedTasksImmediately(ped);
                FreezeEntityPosition(ped, true);
                SetEntityVelocity(ped, 0.0, 0.0, 0.0);
            }
        }
    }
}

function guardPauseMenu() {
    if (pauseGuardUntil <= 0 && !deferredCursorExit) return;

    const controls = [199, 200, 202, 322];
    for (const control of controls) DisableControlAction(0, control, true);
    SetPauseMenuActive(false);

    const held = controls.some((control) =>
        IsDisabledControlPressed(0, control) || IsControlPressed(0, control)
    );

    if (held) {
        pauseGuardUntil = GetGameTimer() + 250;
        return;
    }

    if (pauseGuardUntil <= 0) pauseGuardUntil = GetGameTimer() + 250;
    if (GetGameTimer() < pauseGuardUntil) return;

    if (deferredCursorExit) {
        try { LeaveCursorMode(); } catch (_) {}
        deferredCursorExit = false;
    }
    resetCursor();
    pauseGuardUntil = 0;
}

function start(entity, id, options) {
    if (deferredCursorExit) {
        try { LeaveCursorMode(); } catch (_) {}
        deferredCursorExit = false;
        pauseGuardUntil = 0;
    }
    if (session) {
        emit('DTlib:gizmo:result', id, {
            id,
            entity,
            confirmed: false,
            cancelled: true,
            reason: 'busy',
        });
        return;
    }

    if (!entity || !DoesEntityExist(entity)) {
        emit('DTlib:gizmo:result', id, {
            id,
            entity: entity || 0,
            confirmed: false,
            cancelled: true,
            reason: 'entity_missing',
        });
        return;
    }

    const snap = snapshot(entity);
    const opts = options || {};
    session = {
        id: id || `dtlib_${++sequence}`,
        entity,
        options: opts,
        snapshot: snap,
        origin: opts.origin ? {
            x: Number(opts.origin.x || 0.0),
            y: Number(opts.origin.y || 0.0),
            z: Number(opts.origin.z || 0.0),
        } : { ...snap.coords },
        lastChange: 0,
        limited: false,
        localMode: false,
        cursorEntered: true,
        pointerDown: false,
        pressCursor: cursorPosition(),
        lastCursor: cursorPosition(),
        gizmoChangedSincePress: false,
        gizmoDragging: false,
        cameraDragging: false,
        cam: 0,
        camTarget: null,
        playerPed: PlayerPedId(),
        frozenPeds: new Map(),
        radius: 0.0,
        theta: 0.0,
        phi: 1.0,
    };

    EnterCursorMode();
    if (opts.camera !== 'gameplay' && opts.cameraMode !== 'gameplay') {
        ensureOrbitCamera(session);
        updateOrbitCamera(session);
    }
    setPlacementCursor(session);

    if (opts.outline !== false) {
        const color = opts.outlineColor || { r: 96, g: 195, b: 255, a: 220 };
        SetEntityDrawOutlineColor(
            Number(color.r ?? 96), Number(color.g ?? 195),
            Number(color.b ?? 255), Number(color.a ?? 220)
        );
        SetEntityDrawOutlineShader(Number(opts.outlineShader || 0));
        SetEntityDrawOutline(entity, true);
    }
}

on('DTlib:gizmo:start', (entity, id, options) => start(Number(entity), String(id), options || {}));
on('DTlib:gizmo:cancel', (id) => {
    if (session && (!id || String(id) === session.id)) finish(true, 'cancelled');
});
on('DTlib:gizmo:confirm', (id) => {
    if (session && (!id || String(id) === session.id)) finish(false, 'confirmed');
});

// Cfx owns the +gizmo* commands internally. DTlib only forwards controls.
RegisterCommand('+dtlibGizmoSelect', () => {
    if (!session) return;
    session.pointerDown = true;
    session.pressCursor = cursorPosition();
    session.lastCursor = session.pressCursor;
    session.gizmoChangedSincePress = false;
    session.gizmoDragging = false;
    session.cameraDragging = false;
    ExecuteCommand('+gizmoSelect');
}, false);
RegisterCommand('-dtlibGizmoSelect', () => {
    ExecuteCommand('-gizmoSelect');
    if (!session) return;
    session.pointerDown = false;
    session.gizmoDragging = false;
    session.cameraDragging = false;
    session.gizmoChangedSincePress = false;
}, false);
RegisterKeyMapping('+dtlibGizmoSelect', 'DTlib Placement: Select gizmo axis', 'MOUSE_BUTTON', 'MOUSE_LEFT');

RegisterCommand('+dtlibGizmoTranslate', () => {
    if (session) ExecuteCommand('+gizmoTranslation');
}, false);
RegisterCommand('-dtlibGizmoTranslate', () => {
    ExecuteCommand('-gizmoTranslation');
}, false);
RegisterKeyMapping('+dtlibGizmoTranslate', 'DTlib Placement: Translate mode', 'keyboard', 'W');

RegisterCommand('+dtlibGizmoRotate', () => {
    if (session) ExecuteCommand('+gizmoRotation');
}, false);
RegisterCommand('-dtlibGizmoRotate', () => {
    ExecuteCommand('-gizmoRotation');
}, false);
RegisterKeyMapping('+dtlibGizmoRotate', 'DTlib Placement: Rotate mode', 'keyboard', 'R');

RegisterCommand('+dtlibGizmoScale', () => {
    if (session && session.options.enableScale === true) ExecuteCommand('+gizmoScale');
}, false);
RegisterCommand('-dtlibGizmoScale', () => {
    ExecuteCommand('-gizmoScale');
}, false);
RegisterKeyMapping('+dtlibGizmoScale', 'DTlib Placement: Scale mode', 'keyboard', 'S');

RegisterCommand('dtlibGizmoToggleLocal', () => {
    if (!session) return;
    session.localMode = !session.localMode;
    ExecuteCommand(session.localMode ? '+gizmoLocal' : '-gizmoLocal');
}, false);
RegisterKeyMapping('dtlibGizmoToggleLocal', 'DTlib Placement: Toggle local/world', 'keyboard', 'Q');

RegisterCommand('+dtlibPlacementGround', () => {
    if (!session || session.options.snapToGround === false || !DoesEntityExist(session.entity)) return;
    PlaceObjectOnGroundProperly_2(session.entity);
    clampDistance(session);
    pushChange(session);
}, false);
RegisterCommand('-dtlibPlacementGround', () => {}, false);
RegisterKeyMapping('+dtlibPlacementGround', 'DTlib Placement: Snap object to ground', 'keyboard', 'LMENU');

on('onResourceStop', (resourceName) => {
    if (resourceName !== GetCurrentResourceName()) return;
    if (session) {
        const active = session;
        session = null;
        releaseGizmoControls(active, false);
    }
    if (deferredCursorExit) {
        try { LeaveCursorMode(); } catch (_) {}
        deferredCursorExit = false;
    }
    pauseGuardUntil = 0;
});

setTick(() => {
    guardPauseMenu();
    if (!session) return;
    const active = session;

    if (!DoesEntityExist(active.entity)) {
        finish(true, 'entity_missing');
        return;
    }

    disableGameplay(active);

    const matrix = makeEntityMatrix(active.entity);
    let changed = false;
    try {
        changed = !!DrawGizmo(matrix, `DTlib:${active.id}`);
    } catch (error) {
        emit('DTlib:gizmo:error', active.id, String(error && error.message ? error.message : error));
        finish(true, 'gizmo_error');
        return;
    }

    if (changed) {
        // IMPORTANT: this remains the exact v1.0.6 transform path. Camera orbit
        // never scales/interpolates the matrix returned by DrawGizmo.
        active.gizmoChangedSincePress = active.pointerDown || active.gizmoChangedSincePress;
        active.gizmoDragging = active.pointerDown;
        applyEntityMatrix(active.entity, matrix, active.options.enableScale === true);
        clampDistance(active);
        pushChange(active);
    } else if (!active.pointerDown) {
        active.gizmoDragging = false;
    }

    handleOrbitInput(active);
    setPlacementCursor(active);

    // ENTER / frontend accept.
    DisableControlAction(0, 191, true);
    if (IsDisabledControlJustPressed(0, 191)) {
        finish(false, 'confirmed');
        return;
    }

    // ESC / frontend cancel. Pause controls stay consumed after close until release.
    DisableControlAction(0, 200, true);
    DisableControlAction(0, 202, true);
    DisableControlAction(0, 322, true);
    if (IsDisabledControlJustPressed(0, 200) || IsDisabledControlJustPressed(0, 202) || IsDisabledControlJustPressed(0, 322)) {
        if (active.options.enableCancel === false) return;
        finish(true, 'cancelled');
    }
});
