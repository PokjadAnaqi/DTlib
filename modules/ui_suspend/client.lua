local suspendTokens = {}
local suspendCount = 0
local tokenCounter = 0
local restoreState = nil
local lastPlacementState = nil
local restoreGeneration = 0

DT.UI = DT.UI or {}

local function started(resource)
    local state = GetResourceState(resource)
    return state == 'started' or state == 'starting'
end

local function tryExport(resource, exportName, ...)
    if not started(resource) then return false, nil end
    local args = table.pack(...)
    local ok, result = pcall(function()
        local handle = exports[resource]
        local fn = handle[exportName]
        return fn(handle, table.unpack(args, 1, args.n))
    end)
    return ok, result
end

local function getBoolean(resource, names)
    for i = 1, #names do
        local ok, value = tryExport(resource, names[i])
        if ok and type(value) == 'boolean' then return value end
    end
    return nil
end

local function setByFirstExport(resource, names, value, extra)
    for i = 1, #names do
        local ok = tryExport(resource, names[i], value, extra)
        if ok then return names[i] end
    end
    return nil
end

local overlaySpecs = {
    temperature = {
        resource = 'DT_temperature',
        getters = { 'IsVisible', 'IsUIVisible', 'GetVisible', 'IsTempUIVisible', 'IsTemperatureUIVisible' },
        setters = { 'SetVisible', 'SetUIVisible', 'SetTempUIVisible', 'SetTemperatureUIVisible', 'SetWidgetVisible' },
        toggles = { 'ToggleVisible', 'ToggleTemperatureUI' },
        forceRestoreSetters = {
            'SetVisible', 'SetUIVisible', 'SetTempUIVisible',
            'SetTemperatureUIVisible', 'SetWidgetVisible',
        },
        hideEvents = {
            'DT_temperature:client:setPlacementHidden',
            'DT_temperature:client:setTemporaryUIHidden',
        },
        restoreEvents = {
            'DT_temperature:client:setPlacementHidden',
            'DT_temperature:client:setTemporaryUIHidden',
        },
    },
    radiation = {
        resource = 'DT_radiation',
        getters = { 'IsVisibleAllowed', 'IsVisible', 'IsUIVisible', 'GetVisible' },
        setters = { 'SetVisible', 'SetUIVisible', 'SetRadiationUIVisible', 'SetWidgetVisible' },
        toggles = { 'ToggleVisible' },
        hideEvents = {
            'DT_radiation:client:setPlacementHidden',
            'DT_radiation:client:setTemporaryUIHidden',
        },
        restoreEvents = {
            'DT_radiation:client:setPlacementHidden',
            'DT_radiation:client:setTemporaryUIHidden',
        },
    },
    survivalHud = {
        resource = 'SAG-survival-hud',
        getters = { 'IsVisible', 'GetVisibility', 'GetVisible' },
        setters = { 'hudVisibility', 'SetVisible', 'SetHUDVisible' },
        toggles = {},
    },
    zeroHud = {
        resource = '0r-hud-v3',
        getters = { 'IsVisible', 'GetVisibility', 'GetVisible' },
        setters = { 'SetVisible', 'SetHUDVisible', 'SetHudVisible' },
        toggles = { 'ToggleVisible' },
    },
}

local function triggerOverlayEvents(events, hidden, reason)
    if type(events) ~= 'table' then return end
    for i = 1, #events do
        TriggerEvent(events[i], hidden, reason or 'DTlib:placement')
    end
end

local function hideOverlay(spec, reason)
    if not started(spec.resource) then return nil end

    local state = {
        resource = spec.resource,
        visible = getBoolean(spec.resource, spec.getters or {}),
        mode = nil,
        method = nil,
        changed = false,
    }

    local setter = setByFirstExport(spec.resource, spec.setters or {}, false, reason)
    if setter then
        state.mode = 'setter'
        state.method = setter
        state.changed = true
    else
        -- ToggleVisible-style APIs must only be invoked once on hide and once
        -- on restore. Replaying them in restore retries flips the UI off again.
        if state.visible ~= false then
            for i = 1, #(spec.toggles or {}) do
                local toggle = spec.toggles[i]
                local ok = tryExport(spec.resource, toggle, false, reason)
                if ok then
                    state.mode = 'toggle'
                    state.method = toggle
                    state.changed = true
                    break
                end
            end
        end
    end

    triggerOverlayEvents(spec.hideEvents, true, reason)
    return state
end

local function restoreOverlay(spec, state, includeOneShots, reason)
    if not started(spec.resource) then return end
    state = state or {}

    triggerOverlayEvents(spec.restoreEvents, false, reason)

    local wantedVisible = state.visible ~= false

    if state.mode == 'setter' and state.method then
        -- If the getter is unavailable, the overlay was explicitly hidden by
        -- DTlib, so restoring to visible is the safest placement recovery.
        tryExport(spec.resource, state.method, wantedVisible, reason)
    elseif state.mode == 'toggle' and state.method and state.changed and includeOneShots then
        -- Exactly one inverse toggle. Never run this in delayed restore retries.
        tryExport(spec.resource, state.method, true, reason)
    elseif not state.mode and includeOneShots then
        -- Compatibility fallback for resources that gained a setter while the
        -- placement was open or whose getter/export was not ready on hide.
        setByFirstExport(spec.resource, spec.setters or {}, wantedVisible, reason)
    end

    -- Reassert visibility during delayed placement recovery. This is important
    -- for NUI widgets such as DT_temperature whose first show message can land
    -- while the scripted placement camera is still blending out.
    if wantedVisible and type(spec.forceRestoreSetters) == 'table' then
        setByFirstExport(spec.resource, spec.forceRestoreSetters, true, reason)
    end
end

local function hideQuest(reason)
    if not started('DT_questsystem') then return nil end

    local wasVisible = getBoolean('DT_questsystem', {
        'IsTrackerVisible', 'GetTrackerVisible', 'IsTrackerEnabled', 'GetTrackerEnabled'
    })
    local state = { visible = wasVisible, method = nil, mode = nil, changed = false }

    local hiddenSetter = setByFirstExport('DT_questsystem', {
        'SetTrackerSuppressed', 'SetTemporaryTrackerHidden', 'SetTrackerHidden'
    }, true, reason)
    if hiddenSetter then
        state.method = hiddenSetter
        state.mode = 'hidden'
        state.changed = true
    else
        local visibleSetter = setByFirstExport('DT_questsystem', {
            'SetTrackerVisible'
        }, false, true)
        if visibleSetter then
            state.method = visibleSetter
            state.mode = 'visible'
            state.changed = true
        elseif wasVisible ~= false then
            local ok = tryExport('DT_questsystem', 'HideTracker', true)
            if ok then
                state.method = 'HideTracker'
                state.mode = 'hide_show'
                state.changed = true
            end
        end
    end

    -- Temporary events never touch the persistent /tracker preference.
    TriggerEvent('DT_questsystem:client:setTrackerSuppressed', true, reason)
    TriggerEvent('DT_questsystem:client:setTemporaryUIHidden', true, reason)
    TriggerEvent('DT_questsystem:client:setPlacementHidden', true, reason)
    return state
end

local function restoreQuest(state, includeOneShots, reason)
    if not started('DT_questsystem') then return end
    state = state or {}

    if state.mode == 'visible' and state.method then
        setByFirstExport('DT_questsystem', { state.method }, state.visible ~= false, true)
    elseif state.mode == 'hidden' and state.method then
        setByFirstExport('DT_questsystem', { state.method }, false, reason)
    elseif state.mode == 'hide_show' and state.changed and includeOneShots then
        if state.visible ~= false then
            tryExport('DT_questsystem', 'ShowTracker', true)
        end
    elseif includeOneShots then
        -- If the resource only exposes temporary placement events, the events
        -- below are sufficient. If a setter appears later, recover it too.
        setByFirstExport('DT_questsystem', { 'SetTrackerSuppressed', 'SetTemporaryTrackerHidden', 'SetTrackerHidden' }, false, reason)
    end

    TriggerEvent('DT_questsystem:client:setTrackerSuppressed', false, reason)
    TriggerEvent('DT_questsystem:client:setTemporaryUIHidden', false, reason)
    TriggerEvent('DT_questsystem:client:setPlacementHidden', false, reason)
end

local function hideExternal(reason)
    reason = reason or 'placement'
    local state = {
        hudVisible = not IsHudHidden(),
        radarVisible = not IsRadarHidden(),
        overlays = {},
        quest = nil,
    }

    for key, spec in pairs(overlaySpecs) do
        state.overlays[key] = hideOverlay(spec, ('DTlib:%s'):format(reason))
    end

    state.quest = hideQuest(('DTlib:%s'):format(reason))

    TriggerEvent('DTlib:ui:suspend', reason)
    return state
end

local function applyExternalRestore(state, includeOneShots, reason)
    if suspendCount > 0 then return false end
    state = state or {}
    reason = reason or 'placement'

    -- Reassert the shared state on every restore pass. DT ecosystem UIs that
    -- consume this state can recover even if their first NUI show message was
    -- sent while the placement camera was still tearing down.
    LocalPlayer.state:set('dtlibUiSuspended', false, false)
    LocalPlayer.state:set('dtlibUiSuspendReason', '', false)

    for key, spec in pairs(overlaySpecs) do
        restoreOverlay(spec, state.overlays and state.overlays[key] or nil, includeOneShots, ('DTlib:%s'):format(reason))
    end

    restoreQuest(state.quest, includeOneShots, ('DTlib:%s'):format(reason))

    DisplayHud(state.hudVisible ~= false)
    DisplayRadar(state.radarVisible ~= false)
    TriggerEvent('DTlib:ui:resume', reason)
    TriggerEvent('DTlib:placement:uiRestored', reason)
    return true
end

local function restoreExternal(state, reason)
    restoreGeneration = restoreGeneration + 1
    local generation = restoreGeneration

    -- One-shot toggle APIs are invoked only here. Delayed passes reassert only
    -- setter/event-based visibility so ToggleVisible can never flip back off.
    applyExternalRestore(state, true, reason)

    CreateThread(function()
        local waits = { 100, 250, 500, 900, 1500, 2500, 4000 }
        for i = 1, #waits do
            Wait(waits[i])
            if generation ~= restoreGeneration or suspendCount > 0 then return end
            applyExternalRestore(state, false, reason)
        end
    end)
end

local function finishRestore(state, reason)
    restoreState = nil
    lastPlacementState = nil
    restoreExternal(state or {}, reason or 'placement')
end

function DT.UI.RestorePlacement(force)
    local removed = false
    for token, reason in pairs(suspendTokens) do
        if reason == 'placement' then
            suspendTokens[token] = nil
            suspendCount = math.max(0, suspendCount - 1)
            removed = true
        end
    end

    if suspendCount == 0 and (removed or force == true) then
        LocalPlayer.state:set('dtlibUiSuspended', false, false)
        LocalPlayer.state:set('dtlibUiSuspendReason', '', false)
        local state = restoreState or lastPlacementState or {}
        finishRestore(state, 'placement')
        return true
    end

    return removed
end

DT.UI.RecoverPlacement = DT.UI.RestorePlacement

function DT.UI.IsSuspended()
    return suspendCount > 0
end

function DT.UI.Suspend(reason)
    reason = reason or 'unknown'
    tokenCounter = tokenCounter + 1
    local token = ('dtlib-ui-%s-%s'):format(GetGameTimer(), tokenCounter)
    suspendTokens[token] = reason
    suspendCount = suspendCount + 1

    if suspendCount == 1 then
        restoreGeneration = restoreGeneration + 1
        restoreState = hideExternal(reason)
        if reason == 'placement' then
            lastPlacementState = restoreState
        end
        LocalPlayer.state:set('dtlibUiSuspended', true, false)
        LocalPlayer.state:set('dtlibUiSuspendReason', tostring(reason), false)
    end

    return token
end

function DT.UI.Resume(token)
    local reason = token and suspendTokens[token] or nil

    if token and reason then
        suspendTokens[token] = nil
        suspendCount = math.max(0, suspendCount - 1)
    elseif not token and suspendCount > 0 then
        suspendTokens = {}
        suspendCount = 0
        reason = 'unknown'
    else
        return false
    end

    if suspendCount == 0 then
        LocalPlayer.state:set('dtlibUiSuspended', false, false)
        LocalPlayer.state:set('dtlibUiSuspendReason', '', false)
        local state = restoreState or (reason == 'placement' and lastPlacementState or nil) or {}
        finishRestore(state, reason or 'unknown')
    end

    return true
end

CreateThread(function()
    while true do
        if suspendCount > 0 then
            HideHudAndRadarThisFrame()
            for component = 1, 22 do
                HideHudComponentThisFrame(component)
            end
            Wait(0)
        else
            Wait(300)
        end
    end
end)

exports('UISuspend', DT.UI.Suspend)
exports('UIResume', DT.UI.Resume)
exports('UIIsSuspended', DT.UI.IsSuspended)
exports('UIRestorePlacement', DT.UI.RestorePlacement)
exports('UIRecoverPlacement', DT.UI.RestorePlacement)
