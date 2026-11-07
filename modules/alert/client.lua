local activeProvider
local function resolveAdapter()
    return DT.UI.Adapter('alert')
end
function DT.Alert.Await(data)
    if activeProvider then
        return nil, 'busy'
    end
    data = type(data) == 'table' and data or { content = tostring(data or '') }
    local adapter = resolveAdapter()
    activeProvider = adapter
    local ok, result = pcall(adapter.await, adapter, data)
    activeProvider = nil
    if ok then
        return result
    end
    DT.Debug('Alert provider failed:', result)
    if adapter.publicName ~= 'native' then
        return DT.Modules.Get('alert', 'native'):await(data)
    end
    return nil, tostring(result)
end
function DT.Alert.Close()
    local adapter = activeProvider or resolveAdapter()
    return adapter and adapter.close and adapter:close() or false
end
DT.Alert.Show = DT.Alert.Await
DT.UI.Alert = DT.Alert.Await
exports('Alert', function(...)
    return DT.Alert.Await(...)
end)
exports('CloseAlert', function(...)
    return DT.Alert.Close(...)
end)
