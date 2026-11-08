local function providerName()
    local uiProvider = DT.UI.Name()
    return uiProvider == 'lation_ui' and 'lation_ui' or uiProvider == 'ox_lib' and 'ox_lib' or 'native'
end
local active = false
local current = nil
local cachedAdapter, cachedKey, cachedResolver
local backendActive, nextActiveCheck = false, 0
local function invalidate()
    cachedAdapter, cachedKey, cachedResolver = nil, nil, nil
    backendActive, nextActiveCheck = false, 0
end
local function resolveAdapter()
    local adapters = DTConfig.Adapters or {}
    local key = tostring(adapters.progress)
        .. ':'
        .. tostring(adapters.ui)
        .. ':'
        .. tostring(DTConfig.Ecosystem and DTConfig.Ecosystem.enabled)
    if not cachedAdapter or key ~= cachedKey or cachedResolver ~= DT.UI.Adapter then
        backendActive, nextActiveCheck = false, 0
        cachedAdapter = DT.UI.Adapter('progressbar')
        cachedKey, cachedResolver = key, DT.UI.Adapter
    end
    return cachedAdapter
end
AddEventHandler('onClientResourceStart', invalidate)
AddEventHandler('onClientResourceStop', invalidate)
AddEventHandler('DTlib:progress:state', function()
    nextActiveCheck = 0
end)
function DT.Progress(data)
    if active then
        return false, 'busy'
    end
    data = DTUtils.copy(data or {})
    active = true
    TriggerEvent('DTlib:progress:state', true)
    current = resolveAdapter()
    local ok, result = pcall(current.run, current, data)
    active = false
    TriggerEvent('DTlib:progress:state', false)
    local name = current and current.publicName
    current = nil
    if not ok and name ~= 'native' then
        DT.Debug('Progress provider failed, using native:', result)
        local adapter = DT.Modules.Get('progressbar', 'native')
        active = true
        TriggerEvent('DTlib:progress:state', true)
        local nativeSucceeded, nativeResult = pcall(adapter.run, adapter, data)
        active = false
        TriggerEvent('DTlib:progress:state', false)
        return nativeSucceeded and nativeResult == true,
            nativeSucceeded and (nativeResult == true and 'complete' or 'cancelled') or 'failed'
    end
    return ok and result == true, ok and (result == true and 'complete' or 'cancelled') or 'failed'
end
function DT.ProgressActive(force)
    if active then
        return true
    end
    local now = GetGameTimer()
    -- Backend polling remains for progress started outside DTlib. Confirm paths can bypass it.
    local adapter = resolveAdapter()
    if force == true or now >= nextActiveCheck then
        backendActive = adapter and adapter.active and adapter:active() == true or false
        nextActiveCheck = now + 200
    end
    return backendActive
end
function DT.ProgressCancel()
    local adapter = current or resolveAdapter()
    return adapter and adapter.cancel and adapter:cancel() or false
end
exports('Progress', function(...)
    return DT.Progress(...)
end)
exports('ProgressActive', function(...)
    return DT.ProgressActive(...)
end)
exports('CancelProgress', function(...)
    return DT.ProgressCancel(...)
end)
