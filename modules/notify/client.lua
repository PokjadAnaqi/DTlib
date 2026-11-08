local aliases = {
    lation = 'lation_ui',
    lationui = 'lation_ui',
    ox = 'ox_lib',
    oxlib = 'ox_lib',
    okok = 'okokNotify',
    okoknotify = 'okokNotify',
    dt = 'native',
    dtlib = 'native',
}
local function resolveAdapter()
    local configured = DTConfig.Adapters.notify or 'auto'
    local candidates = { 'lation_ui', 'ox_lib', 'okokNotify' }
    for _, adapter in ipairs(DTEcosystemCatalog.notify.providers) do
        if not adapter.default and not DTUtils.tableContains(candidates, adapter.resource) then
            candidates[#candidates + 1] = adapter.resource
        end
    end
    return DT.Modules.Resolve('notify', configured, candidates, aliases, 'native')
end
function DT.NotifyProvider()
    local adapter = resolveAdapter()
    return adapter and adapter.publicName or 'native'
end
function DT.Notify(data, description, notifyType)
    local notification = DT.NotifyUtil.payload(data, description, notifyType)
    local adapter = notification.layout == 'banner' and DT.Modules.Get('notify', 'native') or resolveAdapter()
    if adapter and adapter.send then
        local ok, errorMessage = pcall(adapter.send, adapter, notification)
        if ok and errorMessage ~= false then
            return true
        end
        DT.Debug('Notify provider failed, using native:', errorMessage)
    end
    local provider = DT.Modules.Get('notify', 'native')
    return provider and provider:send(notification) or false
end
RegisterNetEvent('DTlib:client:notify', function(data)
    DT.Notify(data)
end)
exports('Notify', function(...)
    return DT.Notify(...)
end)

function DT.NotifyBanner(data)
    local payload = DTUtils.copy(type(data) == 'table' and data or { message = tostring(data or '') })
    payload.layout = 'banner'
    return DT.Notify(payload)
end
exports('NotifyBanner', function(data)
    return DT.NotifyBanner(data)
end)

function DT.RemoveNotifyBanner(id)
    if type(id) ~= 'string' and type(id) ~= 'number' then
        return false
    end
    SendNUIMessage({ action = 'notify:remove', data = { id = id } })
    return true
end
RegisterNetEvent('DTlib:client:removeNotifyBanner', function(id)
    DT.RemoveNotifyBanner(id)
end)
exports('RemoveNotifyBanner', function(id)
    return DT.RemoveNotifyBanner(id)
end)
