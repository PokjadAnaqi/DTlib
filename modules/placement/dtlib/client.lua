local activeSession = nil
local placementCounter = 0
local pauseReleaseGuard = false
local pauseReleaseUntil = 0
local normaliseResult

-- Full placement input lockdown. DTlib reads placement controls through
-- registered key mappings / disabled-control state, while every GTA PAD control
-- remains disabled so no key or mouse button can trigger PED behaviour.
local function rememberFrozenPed(sessionRef, ped)
    if not sessionRef or not ped or ped == 0 or not DoesEntityExist(ped) then return end
    sessionRef.frozenPeds = sessionRef.frozenPeds or {}
    if sessionRef.frozenPeds[ped] == nil then
        sessionRef.frozenPeds[ped] = IsEntityPositionFrozen(ped) == true
    end
end

local function restoreFrozenPeds(sessionRef)
    if not sessionRef or type(sessionRef.frozenPeds) ~= 'table' then return end
    for ped, wasFrozen in pairs(sessionRef.frozenPeds) do
        if DoesEntityExist(ped) then
            FreezeEntityPosition(ped, wasFrozen == true)
            if wasFrozen ~= true then SetEntityVelocity(ped, 0.0, 0.0, 0.0) end
        end
    end
    sessionRef.frozenPeds = {}
end

local function lockPlacementPlayer(sessionRef)
    if not sessionRef or sessionRef.freezePlayer == false then return end

    local ped = PlayerPedId()
    if ped == 0 or not DoesEntityExist(ped) then return end

    rememberFrozenPed(sessionRef, ped)
    FreezeEntityPosition(ped, true)
    SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    DisablePlayerFiring(PlayerId(), true)

    -- Block the entire gameplay input surface, including LMB/RMB, keyboard,
    -- melee, reload, movement, weapon wheel and vehicle controls. Placement
    -- code continues to use key mappings and GetDisabledControl* readers.
    for pad = 0, 2 do
        DisableAllControlActions(pad)
    end

    -- Kill any task that slipped through on the frame placement was opened.
    ClearPedSecondaryTask(ped)
    if IsPedInMeleeCombat(ped) or IsPedShooting(ped) or IsPedReloading(ped) then
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, true)
        SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    end
end

local function nextId()
    placementCounter = placementCounter + 1
    return ('%s:%s:%s'):format(GetCurrentResourceName(), GetGameTimer(), placementCounter)
end

local function number(value, fallback)
    value = tonumber(value)
    if value == nil then return fallback end
    return value
end

local function copyVec3(value, fallback)
    if type(value) == 'vector3' then
        return { x = value.x + 0.0, y = value.y + 0.0, z = value.z + 0.0 }
    end

    if type(value) == 'vector4' then
        return { x = value.x + 0.0, y = value.y + 0.0, z = value.z + 0.0 }
    end

    if type(value) == 'table' and value.x and value.y and value.z then
        return { x = number(value.x, 0.0), y = number(value.y, 0.0), z = number(value.z, 0.0) }
    end

    if fallback then return copyVec3(fallback) end
    return { x = 0.0, y = 0.0, z = 0.0 }
end

local function toVector3(value)
    value = copyVec3(value)
    return vector3(value.x, value.y, value.z)
end

local function callable(value)
    if DTUtils and DTUtils.isCallable then return DTUtils.isCallable(value) end
    return type(value) == 'function'
end

local function invoke(fn, ...)
    if not callable(fn) then return end
    local ok, err = pcall(fn, ...)
    if not ok then
        if DT.Logger and DT.Logger.Warn then
            DT.Logger.Warn('PLACEMENT', ('Placement callback failed: %s'):format(tostring(err)))
        else
            print(('[DTlib] [PLACEMENT] callback failed: %s'):format(tostring(err)))
        end
    end
end

local function requestControl(entity, timeout)
    if not NetworkGetEntityIsNetworked(entity) then return true end
    if NetworkHasControlOfEntity(entity) then return true end

    local deadline = GetGameTimer() + (timeout or 1000)
    repeat
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    until NetworkHasControlOfEntity(entity) or GetGameTimer() >= deadline

    return NetworkHasControlOfEntity(entity)
end

local function requestModel(model, timeout)
    -- Admin/NUI data may persist model hashes as numeric strings. Treat those
    -- as hashes instead of hashing the decimal text again (joaat('31071109')).
    local numeric = tonumber(model)
    local hash = numeric or joaat(tostring(model or ''))
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil, 'invalid_model'
    end

    RequestModel(hash)
    local deadline = GetGameTimer() + (timeout or 5000)
    while not HasModelLoaded(hash) do
        if GetGameTimer() >= deadline then
            return nil, 'model_timeout'
        end
        Wait(0)
    end

    return hash
end


local function objectGizmoAvailable()
    local state = GetResourceState('object_gizmo')
    if state ~= 'started' then return false, nil end

    local version = GetResourceMetadata('object_gizmo', 'version', 0) or ''
    local major = tonumber(tostring(version):match('(%d+)')) or 0
    local required = DTConfig.Placement and DTConfig.Placement.objectGizmoMajor or 3
    return major >= required, version
end

local function placementProvider(requested)
    local configured = requested and tostring(requested):lower() or (DTConfig.Placement and tostring(DTConfig.Placement.provider or 'native'):lower() or 'native')
    if configured == 'native' or configured == 'dtlib' or configured == 'dtlib_gizmo' or configured == 'legacy' or configured == 'v1.0.6' then
        return 'dtlib_gizmo'
    end

    if configured == 'object_gizmo' or configured == 'object' or configured == 'external' or configured == 'auto' then
        local available, version = objectGizmoAvailable()
        if available then return 'object_gizmo', version end
    end

    return 'dtlib_gizmo'
end

local function objectGizmoOptions(options, origin)
    local defaults = DTConfig.Placement and DTConfig.Placement.objectGizmo or {}
    local orbitDefaults = defaults.orbit or {}
    local orbit = type(options.orbit) == 'table' and options.orbit or {}

    return {
        camera = options.camera or options.cameraMode or defaults.camera or 'orbit',
        mode = options.mode or defaults.mode or 'translate',
        space = options.space or defaults.space or 'world',
        pivot = options.pivot or defaults.pivot or 'center',
        enableScale = options.enableScale == true,
        enableRotate = options.enableRotate ~= false,
        enableTranslate = options.enableTranslate ~= false,
        enableSnapToggle = options.enableSnapToggle ~= false,
        enableCopy = options.enableCopy ~= false,
        enableCancel = options.enableCancel ~= false,
        snapToGround = options.snapToGround ~= false,
        translationSnap = number(options.translationSnap, defaults.translationSnap or 0.25),
        rotationSnap = number(options.rotationSnap, defaults.rotationSnap or 15.0),
        scaleSnap = number(options.scaleSnap, defaults.scaleSnap or 0.1),
        snap = options.snap == true,
        outline = options.outline ~= false,
        outlineColor = options.outlineColor,
        outlineShader = number(options.outlineShader, 0),
        pedAlpha = number(options.pedAlpha, 200),
        freezeEntity = options.freezeEntity ~= false,
        freezePlayer = options.freezePlayer ~= false,
        disableCollision = options.disableCollision == true,
        playerCanMove = options.playerCanMove == true,
        restoreOnCancel = options.restoreOnCancel ~= false,
        requestControl = options.requestControl ~= false,
        showCoords = options.showCoords ~= false,
        prompts = options.prompts ~= false,
        promptPosition = options.promptPosition or 'bottom-center',
        promptLayout = options.promptLayout or 'row',
        textUiPosition = options.textUiPosition or options.helpPosition or 'right-center',
        gizmoSize = number(options.gizmoSize, defaults.gizmoSize or 0.5),
        distanceLimit = number(options.distanceLimit, 0.0),
        origin = options.origin or origin,
        bounds = options.bounds,
        axes = options.axes,
        orbit = {
            minRadius = number(orbit.minRadius or options.cameraMinDistance, orbitDefaults.minRadius or 1.5),
            maxRadius = number(orbit.maxRadius or options.cameraMaxDistance, orbitDefaults.maxRadius or 25.0),
            zoomStep = number(orbit.zoomStep or options.cameraZoomStep, orbitDefaults.zoomStep or 0.75),
            sensitivity = number(orbit.sensitivity, orbitDefaults.sensitivity or 0.005),
            blend = number(orbit.blend, orbitDefaults.blend or 250)
        }
    }
end

local function sameVec(a, b, epsilon)
    if not a or not b then return false end
    epsilon = epsilon or 0.0005
    return math.abs(a.x - b.x) <= epsilon
        and math.abs(a.y - b.y) <= epsilon
        and math.abs(a.z - b.z) <= epsilon
end

local function startExternalChangeWatcher(sessionRef)
    CreateThread(function()
        local lastCoords = DoesEntityExist(sessionRef.entity) and GetEntityCoords(sessionRef.entity) or nil
        local lastRotation = DoesEntityExist(sessionRef.entity) and GetEntityRotation(sessionRef.entity, 2) or nil
        local interval = math.max(25, number(sessionRef.options.changeInterval, 75))

        while activeSession == sessionRef and sessionRef.provider == 'object_gizmo' do
            Wait(interval)
            if activeSession ~= sessionRef or not DoesEntityExist(sessionRef.entity) then break end

            local coords = GetEntityCoords(sessionRef.entity)
            local rotation = GetEntityRotation(sessionRef.entity, 2)
            if not sameVec(coords, lastCoords) or not sameVec(rotation, lastRotation, 0.01) then
                lastCoords, lastRotation = coords, rotation
                local result = normaliseResult({ reason = 'changed' }, sessionRef.entity)
                invoke(sessionRef.options.onChange, result)
                TriggerEvent('DTlib:placement:changed', result)
                if sessionRef.bridgeToken then
                    TriggerEvent('DTlib:placement:bridge:change', sessionRef.bridgeToken, result)
                end
            end
        end
    end)
end

local function placementHelp(options)
    if type(options.helpData) == 'table' then
        return DTUtils.copy(options.helpData)
    end

    if type(options.helpText) == 'string' and options.helpText ~= '' then
        return {
            title = options.helpTitle or 'CONTROLS',
            description = options.helpText,
            position = options.helpPosition or 'right-center',
            icon = options.helpIcon or 'fa-solid fa-up-down-left-right'
        }
    end

    local controls = {
        {
            label = 'Move / Translate',
            icon = 'fa-solid fa-up-down-left-right',
            keybind = 'W'
        },
        {
            label = 'Rotate',
            icon = 'fa-solid fa-rotate',
            keybind = 'R'
        }
    }

    if options.enableScale == true then
        controls[#controls + 1] = {
            label = 'Scale',
            icon = 'fa-solid fa-maximize',
            keybind = 'S'
        }
    end

    controls[#controls + 1] = {
        label = 'Local / World',
        icon = 'fa-solid fa-globe',
        keybind = 'Q'
    }

    if options.__objectGizmoProvider == true and options.enableSnapToggle ~= false then
        controls[#controls + 1] = {
            label = 'Toggle Snap',
            icon = 'fa-solid fa-magnet',
            keybind = 'X'
        }
    end

    if options.__objectGizmoProvider == true and options.enableCopy ~= false then
        controls[#controls + 1] = {
            label = 'Copy Transform',
            icon = 'fa-solid fa-copy',
            keybind = 'C'
        }
    end

    if (options.camera or options.cameraMode or 'orbit') ~= 'gameplay' then
        controls[#controls + 1] = {
            label = 'Orbit Object Camera',
            icon = 'fa-solid fa-camera-rotate',
            keybind = 'LMB DRAG'
        }
        controls[#controls + 1] = {
            label = 'Zoom Object Camera',
            icon = 'fa-solid fa-magnifying-glass',
            keybind = 'WHEEL'
        }
    end

    if options.snapToGround ~= false then
        controls[#controls + 1] = {
            label = 'Snap to Ground',
            icon = 'fa-solid fa-arrow-down',
            keybind = 'LALT'
        }
    end

    controls[#controls + 1] = {
        label = 'Confirm',
        icon = 'fa-solid fa-check',
        iconColor = '#2dd4a7',
        keybind = 'ENTER'
    }

    if options.enableCancel ~= false then
        controls[#controls + 1] = {
            label = 'Cancel',
            icon = 'fa-solid fa-xmark',
            iconColor = '#ef6464',
            keybind = 'ESC'
        }
    end

    return {
        title = options.helpTitle or 'CONTROLS',
        description = options.helpDescription or 'Place the object where desired',
        position = options.helpPosition or 'right-center',
        icon = options.helpIcon or 'fa-solid fa-cube',
        iconColor = options.helpIconColor or '#9db34f',
        bgColor = options.helpBgColor or '#1E1F24',
        txtColor = options.helpTextColor or '#E4E4E7',
        options = controls,
        allowWhileSuspended = true
    }
end

local function showHud(options)
    if options.showHelp == false or not DT.TextUI or not DT.TextUI.Show then return end
    pcall(DT.TextUI.Show, placementHelp(options))
end

local function hideHud(options)
    if options.showHelp == false or not DT.TextUI or not DT.TextUI.Hide then return end
    pcall(DT.TextUI.Hide)
end

local function startObjectGizmoHudBridge(sessionRef)
    if not DT.UI or not DT.UI.UsingLation or not DT.UI.UsingLation() then return false end
    if sessionRef.options.showHelp == false then return false end
    if GetResourceState('sleepless_prompts') == 'started' then return false end

    sessionRef.options.__objectGizmoProvider = true
    showHud(sessionRef.options)

    -- object_gizmo v3 falls back to ox_lib TextUI when sleepless_prompts is not
    -- running. When DTlib is configured for Lation, suppress only that ox_lib
    -- control panel so the DT Lation panel is the single placement helper.
    CreateThread(function()
        while activeSession == sessionRef and sessionRef.provider == 'object_gizmo' do
            if GetResourceState('sleepless_prompts') ~= 'started' and GetResourceState('ox_lib') == 'started' then
                pcall(function() exports['ox_lib']:hideTextUI() end)
            end
            Wait(100)
        end
    end)

    return true
end


normaliseResult = function(data, entity)
    data = type(data) == 'table' and data or {}
    local coords = data.coords or data.position
    local rotation = data.rotation

    if DoesEntityExist(entity) then
        coords = coords or GetEntityCoords(entity)
        rotation = rotation or GetEntityRotation(entity, 2)
    end

    local result = {
        id = data.id,
        entity = entity,
        handle = entity,
        confirmed = data.confirmed == true,
        cancelled = data.cancelled == true,
        reason = data.reason or (data.confirmed == true and 'confirmed' or (data.cancelled == true and 'cancelled' or nil)),
        limited = data.limited == true,
        coords = toVector3(coords),
        position = toVector3(coords),
        rotation = toVector3(rotation),
        heading = number(data.heading, DoesEntityExist(entity) and GetEntityHeading(entity) or 0.0)
    }

    return result
end

local function busyResult(entity)
    local coords = DoesEntityExist(entity) and GetEntityCoords(entity) or vector3(0.0, 0.0, 0.0)
    local rotation = DoesEntityExist(entity) and GetEntityRotation(entity, 2) or vector3(0.0, 0.0, 0.0)
    return {
        entity = entity or 0,
        handle = entity or 0,
        confirmed = false,
        cancelled = true,
        reason = 'busy',
        coords = coords,
        position = coords,
        rotation = rotation,
        heading = DoesEntityExist(entity) and GetEntityHeading(entity) or 0.0
    }
end

local function serialisableOptions(options, origin)
    -- Prop transform remains the exact direct v1.0.6 manipulation path.
    -- Camera input is isolated from entity transform: empty-space LMB drag orbits
    -- the object, while DrawGizmo handle drag stays direct 1:1.
    local defaults = DTConfig.Placement and DTConfig.Placement.nativeOrbit or {}
    local orbit = type(options.orbit) == 'table' and options.orbit or {}
    return {
        enableScale = options.enableScale == true,
        enableCancel = options.enableCancel ~= false,
        restoreOnCancel = options.restoreOnCancel ~= false,
        snapToGround = options.snapToGround ~= false,
        blockInput = options.blockInput ~= false,
        outline = options.outline ~= false,
        outlineColor = options.outlineColor,
        outlineShader = number(options.outlineShader, 0),
        distanceLimit = number(options.distanceLimit, 0.0),
        changeInterval = number(options.changeInterval, 75),
        camera = options.camera or options.cameraMode or 'orbit',
        orbit = {
            minRadius = number(orbit.minRadius or options.cameraMinDistance, defaults.minRadius or 1.5),
            maxRadius = number(orbit.maxRadius or options.cameraMaxDistance, defaults.maxRadius or 25.0),
            zoomStep = number(orbit.zoomStep or options.cameraZoomStep, defaults.zoomStep or 0.75),
            sensitivity = number(orbit.sensitivity or options.cameraSensitivity, defaults.sensitivity or 0.005),
            blend = number(orbit.blend, defaults.blend or 250),
            dragThresholdPx = number(orbit.dragThresholdPx, defaults.dragThresholdPx or 4.0)
        },
        origin = copyVec3(options.origin, origin)
    }
end

AddEventHandler('DTlib:gizmo:change', function(id, data)
    if not activeSession or activeSession.id ~= id then return end
    local result = normaliseResult(data, activeSession.entity)
    invoke(activeSession.options.onChange, result)
    TriggerEvent('DTlib:placement:changed', result)
    if activeSession.bridgeToken then
        TriggerEvent('DTlib:placement:bridge:change', activeSession.bridgeToken, result)
    end
end)

AddEventHandler('DTlib:gizmo:error', function(id, message)
    if not activeSession or activeSession.id ~= id then return end
    if DT.Logger and DT.Logger.Error then
        DT.Logger.Error('PLACEMENT', ('Gizmo runtime error: %s'):format(tostring(message)))
    end
end)

AddEventHandler('DTlib:gizmo:result', function(id, data)
    if not activeSession or activeSession.id ~= id then return end
    activeSession.promise:resolve(data)
end)

DT.Placement = DT.Placement or {}
DT.PropPlacement = DT.Placement

function DT.Placement.Provider()
    local provider, version = placementProvider()
    if provider == 'object_gizmo' and version and version ~= '' then
        return ('object_gizmo@%s'):format(version)
    end
    return provider
end

function DT.Placement.IsActive()
    return activeSession ~= nil
end

function DT.Placement.GetState()
    if not activeSession then return nil end
    return {
        id = activeSession.id,
        entity = activeSession.entity,
        resource = activeSession.resource
    }
end

function DT.Placement.Cancel()
    if not activeSession then return false end
    if activeSession.provider == 'object_gizmo' then
        local ok = pcall(function() exports['object_gizmo']:cancelGizmo() end)
        return ok
    end
    TriggerEvent('DTlib:gizmo:cancel', activeSession.id)
    return true
end

function DT.Placement.Confirm()
    if not activeSession then return false end
    if activeSession.provider == 'object_gizmo' then
        local ok = pcall(function() exports['object_gizmo']:confirmGizmo() end)
        return ok
    end
    TriggerEvent('DTlib:gizmo:confirm', activeSession.id)
    return true
end

function DT.Placement.Edit(entity, options)
    entity = tonumber(entity) or 0
    options = type(options) == 'table' and options or {}
    if options.distanceLimit == nil and DTConfig.Placement then options.distanceLimit = DTConfig.Placement.distanceLimit end
    if options.showHelp == nil and DTConfig.Placement then options.showHelp = DTConfig.Placement.showHelp end
    if options.outline == nil and DTConfig.Placement then options.outline = DTConfig.Placement.outline end
    -- Placement controls are an editor state: freeze the PED by default so
    -- W/R/Q/S keybinds cannot move, punch, or trigger gameplay animations.
    if options.freezePlayer == nil then
        options.freezePlayer = not DTConfig.Placement or DTConfig.Placement.freezePlayer ~= false
    end

    if activeSession then return busyResult(entity) end
    if entity == 0 or not DoesEntityExist(entity) then
        local result = busyResult(entity)
        result.reason = 'entity_missing'
        return result
    end

    local provider, providerVersion = placementProvider(options.provider)
    if options.camera == nil and options.cameraMode == nil then options.camera = 'orbit' end
    if provider ~= 'object_gizmo' and options.requestControl ~= false
        and not requestControl(entity, number(options.controlTimeout, 1000)) then
        local result = busyResult(entity)
        result.reason = 'network_control_failed'
        return result
    end

    local id = nextId()
    local promiseHandle = promise.new()
    local origin = GetEntityCoords(entity)
    local wasFrozen = IsEntityPositionFrozen(entity)
    activeSession = {
        id = id,
        entity = entity,
        promise = promiseHandle,
        options = options,
        provider = provider,
        providerVersion = providerVersion,
        resource = GetInvokingResource() or GetCurrentResourceName(),
        bridgeToken = options.__bridgeToken,
        wasFrozen = wasFrozen,
        playerPed = PlayerPedId(),
        playerWasFrozen = IsEntityPositionFrozen(PlayerPedId()),
        freezePlayer = options.freezePlayer ~= false,
        frozenPeds = {},
    }
    local sessionRef = activeSession

    if options.hideUI ~= false and DT.UI and DT.UI.Suspend then
        sessionRef.uiSuspendToken = DT.UI.Suspend('placement')
    end

    if provider ~= 'object_gizmo' and sessionRef.freezePlayer and DoesEntityExist(sessionRef.playerPed) then
        rememberFrozenPed(sessionRef, sessionRef.playerPed)
        FreezeEntityPosition(sessionRef.playerPed, true)
        SetEntityVelocity(sessionRef.playerPed, 0.0, 0.0, 0.0)
    end

    -- Official object_gizmo owns its own prompt/TextUI. DTlib only displays
    -- its Lation/native placement help when the dependency-free fallback is used.
    if provider ~= 'object_gizmo' then
        if options.freezeEntity ~= false then FreezeEntityPosition(entity, true) end
        if options.disableCollision == true then SetEntityCollision(entity, false, false) end
        showHud(options)
    end

    TriggerEvent('DTlib:placement:started', {
        id = id,
        entity = entity,
        resource = sessionRef.resource,
        provider = provider,
        providerVersion = providerVersion
    })

    local raw
    if provider == 'object_gizmo' then
        startExternalChangeWatcher(sessionRef)
        sessionRef.externalHud = startObjectGizmoHudBridge(sessionRef)
        local ok, resultOrError = pcall(function()
            return exports['object_gizmo']:useGizmo(entity, objectGizmoOptions(options, origin))
        end)

        if ok then
            raw = resultOrError
        else
            if DT.Logger and DT.Logger.Warn then
                DT.Logger.Warn('PLACEMENT', ('object_gizmo v3 provider failed; using DTlib fallback: %s'):format(tostring(resultOrError)))
            end
            if sessionRef.externalHud then
                hideHud(options)
                sessionRef.externalHud = nil
            end
            options.__objectGizmoProvider = nil
            sessionRef.provider = 'dtlib_gizmo'
            provider = 'dtlib_gizmo'
            if sessionRef.freezePlayer and DoesEntityExist(sessionRef.playerPed) then
                rememberFrozenPed(sessionRef, sessionRef.playerPed)
                FreezeEntityPosition(sessionRef.playerPed, true)
                SetEntityVelocity(sessionRef.playerPed, 0.0, 0.0, 0.0)
            end
            if options.freezeEntity ~= false then FreezeEntityPosition(entity, true) end
            if options.disableCollision == true then SetEntityCollision(entity, false, false) end
            showHud(options)
            TriggerEvent('DTlib:gizmo:start', entity, id, serialisableOptions(options, origin))
            raw = Citizen.Await(promiseHandle)
        end
    else
        TriggerEvent('DTlib:gizmo:start', entity, id, serialisableOptions(options, origin))
        raw = Citizen.Await(promiseHandle)
    end

    local result = normaliseResult(raw, entity)
    if result.cancelled then
        pauseReleaseGuard = true
        pauseReleaseUntil = GetGameTimer() + 350
    end

    -- Mark inactive before any HUD restore. Several UI resources intentionally
    -- ignore show requests while a placement session is still active.
    if activeSession == sessionRef then activeSession = nil end

    if provider ~= 'object_gizmo' or sessionRef.externalHud then hideHud(options) end
    options.__objectGizmoProvider = nil

    local uiRestored = false
    if sessionRef.uiSuspendToken and DT.UI and DT.UI.Resume then
        local ok, resumed = pcall(DT.UI.Resume, sessionRef.uiSuspendToken)
        uiRestored = ok and resumed == true
        if not uiRestored and DT.Logger and DT.Logger.Warn then
            DT.Logger.Warn('PLACEMENT', 'UI resume failed; forcing placement UI recovery')
        end
        sessionRef.uiSuspendToken = nil
    end
    -- Do not restore twice: Toggle-style HUD exports would otherwise be flipped
    -- off again. Force recovery only if the token resume path did not succeed.
    if not uiRestored and DT.UI and DT.UI.RestorePlacement then
        pcall(DT.UI.RestorePlacement, true)
    end

    if sessionRef.freezePlayer then
        restoreFrozenPeds(sessionRef)
    end

    if DoesEntityExist(entity) then
        -- object_gizmo already restores its own collision/freeze state. Native
        -- fallback requires DTlib cleanup here.
        if provider ~= 'object_gizmo' and options.disableCollision == true then
            SetEntityCollision(entity, true, true)
        end

        if result.confirmed then
            if options.groundOnConfirm == true then
                PlaceObjectOnGroundProperly_2(entity)
                result.coords = GetEntityCoords(entity)
                result.position = result.coords
                result.rotation = GetEntityRotation(entity, 2)
                result.heading = GetEntityHeading(entity)
            end
            if options.freezeAfter ~= nil then
                FreezeEntityPosition(entity, options.freezeAfter == true)
            else
                FreezeEntityPosition(entity, wasFrozen)
            end
        else
            if options.freezeAfterCancel ~= nil then
                FreezeEntityPosition(entity, options.freezeAfterCancel == true)
            else
                FreezeEntityPosition(entity, wasFrozen)
            end
        end
    end

    local finishedOptions = sessionRef.options
    if result.confirmed then invoke(finishedOptions.onConfirm, result)
    else invoke(finishedOptions.onCancel, result) end
    invoke(finishedOptions.onFinish, result)
    TriggerEvent('DTlib:placement:finished', result)

    return result
end


CreateThread(function()
    local pauseControls = { 199, 200, 202, 322 }
    while true do
        if activeSession or pauseReleaseGuard then
            local sessionRef = activeSession

            if sessionRef then
                lockPlacementPlayer(sessionRef)
            end

            for pad = 0, 2 do
                for i = 1, #pauseControls do
                    DisableControlAction(pad, pauseControls[i], true)
                end
            end
            SetPauseMenuActive(false)

            if not activeSession and pauseReleaseGuard then
                local held = false
                for i = 1, #pauseControls do
                    local control = pauseControls[i]
                    if IsDisabledControlPressed(0, control) or IsControlPressed(0, control) then
                        held = true
                        break
                    end
                end

                if held then
                    -- ESC can open the frontend on release. Keep blocking for a
                    -- short grace period after the key is physically released.
                    pauseReleaseUntil = GetGameTimer() + 250
                elseif GetGameTimer() >= pauseReleaseUntil then
                    pauseReleaseGuard = false
                end
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

DT.Placement.Start = DT.Placement.Edit
DT.Placement.UseGizmo = DT.Placement.Edit

function DT.Placement.PlaceProp(model, options)
    options = type(options) == 'table' and options or {}

    local hash, modelError = requestModel(model, number(options.modelTimeout, 5000))
    if not hash then
        return {
            entity = 0,
            handle = 0,
            confirmed = false,
            cancelled = true,
            reason = modelError
        }
    end

    local ped = PlayerPedId()
    local coords
    if options.coords then
        coords = toVector3(options.coords)
    else
        local distance = number(options.forwardDistance, 1.8)
        coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, distance, number(options.heightOffset, 0.0))
    end

    local networked = options.networked == true
    local entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, networked, true, false)
    if entity == 0 or not DoesEntityExist(entity) then
        SetModelAsNoLongerNeeded(hash)
        return {
            entity = 0,
            handle = 0,
            confirmed = false,
            cancelled = true,
            reason = 'create_failed'
        }
    end

    SetEntityHeading(entity, number(options.heading, GetEntityHeading(ped)))
    if options.alpha then SetEntityAlpha(entity, math.floor(number(options.alpha, 255)), false) end
    if options.snapInitialToGround == true then PlaceObjectOnGroundProperly_2(entity) end

    local editOptions = {}
    for key, value in pairs(options) do editOptions[key] = value end
    if editOptions.freezeEntity == nil then editOptions.freezeEntity = true end
    if editOptions.freezeAfter == nil then
        if DTConfig.Placement then
            editOptions.freezeAfter = DTConfig.Placement.freezeAfter
        else
            editOptions.freezeAfter = true
        end
    end
    if editOptions.restoreOnCancel == nil then editOptions.restoreOnCancel = true end

    local result = DT.Placement.Edit(entity, editOptions)
    if result.cancelled and options.deleteOnCancel ~= false and DoesEntityExist(entity) then
        DeleteEntity(entity)
        result.entity = 0
        result.handle = 0
    end

    SetModelAsNoLongerNeeded(hash)
    return result
end

DT.Placement.SpawnProp = DT.Placement.PlaceProp
DT.PropPlacement = DT.Placement

-- Cross-resource event bridge used by @DTlib/init.lua. The awaiting coroutine
-- lives in the consumer resource while the actual placement session remains
-- owned by DTlib, avoiding cross-resource yield/function-reference issues.
AddEventHandler('DTlib:placement:bridge:request', function(token, action, payload)
    if type(token) ~= 'string' or token == '' then return end
    payload = type(payload) == 'table' and payload or {}

    if action == 'cancel' then
        if activeSession and activeSession.bridgeToken == token then DT.Placement.Cancel() end
        return
    end

    if action == 'confirm' then
        if activeSession and activeSession.bridgeToken == token then DT.Placement.Confirm() end
        return
    end

    CreateThread(function()
        local options = type(payload.options) == 'table' and payload.options or {}
        options.__bridgeToken = token

        local result
        if action == 'edit' then
            result = DT.Placement.Edit(payload.entity, options)
        elseif action == 'prop' then
            result = DT.Placement.PlaceProp(payload.model, options)
        else
            result = { confirmed = false, cancelled = true, reason = 'invalid_action' }
        end

        TriggerEvent('DTlib:placement:bridge:response', token, result)
    end)
end)

exports('PlacementEdit', DT.Placement.Edit)
exports('PlacementStart', DT.Placement.Edit)
exports('PlacementUseGizmo', DT.Placement.Edit)
exports('PlacementPlaceProp', DT.Placement.PlaceProp)
exports('PlacementCancel', DT.Placement.Cancel)
exports('PlacementConfirm', DT.Placement.Confirm)
exports('PlacementIsActive', DT.Placement.IsActive)
exports('PlacementProvider', DT.Placement.Provider)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if activeSession then
        local uiRestored = false
        if activeSession.uiSuspendToken and DT.UI and DT.UI.Resume then
            local ok, resumed = pcall(DT.UI.Resume, activeSession.uiSuspendToken)
            uiRestored = ok and resumed == true
        end
        if activeSession.freezePlayer then
            restoreFrozenPeds(activeSession)
        end
        if activeSession.provider == 'object_gizmo' then
            pcall(function() exports['object_gizmo']:cancelGizmo() end)
        else
            TriggerEvent('DTlib:gizmo:cancel', activeSession.id)
        end
        activeSession = nil
        if not uiRestored and DT.UI and DT.UI.RestorePlacement then pcall(DT.UI.RestorePlacement, true) end
    elseif DT.UI and DT.UI.RestorePlacement then
        pcall(DT.UI.RestorePlacement, true)
    end
end)
