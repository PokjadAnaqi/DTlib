local waiter
local active = false
local activeProvider
local function providerName()
    local uiProvider = DT.UI.Name()
    return uiProvider == 'lation_ui' and 'lation_ui' or uiProvider == 'ox_lib' and 'ox_lib' or 'native'
end
local function provider()
    return DT.UI.Adapter('input')
end
local function map(result, fields)
    if type(result) ~= 'table' then
        return result
    end
    local named = false
    local out = {}
    for index = 1, #(fields or {}) do
        local handler = fields[index]
        if handler.name then
            out[handler.name] = result[index]
            named = true
        else
            out[index] = result[index]
        end
    end
    return named and out or result
end
function DT.Input.Await(data)
    TriggerEvent('DTlib:interact:release')
    data = data or {}
    if active or waiter then
        return nil, 'busy'
    end
    local fields = data.fields or data.options or {}
    local adapter = DT.UI.Adapter('input', data.provider)
    activeProvider = adapter
    if adapter.publicName ~= 'native' then
        active = true
        local ok, result = pcall(adapter.await, adapter, data, fields)
        active = false
        activeProvider = nil
        if ok then
            return map(result, fields)
        end
        DT.Debug('Input provider failed, using native:', result)
    end
    waiter = promise.new()
    local selectedAdapter = DT.Modules.Get('input', 'native')
    activeProvider = selectedAdapter
    selectedAdapter:open(data, fields)
    local result = Citizen.Await(waiter)
    waiter = nil
    activeProvider = nil
    return result
end
function DT.Input.Close()
    if activeProvider and activeProvider.publicName ~= 'native' and active then
        local ok, result = pcall(activeProvider.close, activeProvider)
        return ok and result ~= false
    end
    if waiter then
        local adapter = DT.Modules.Get('input', 'native')
        if adapter then
            adapter:close()
        end
        waiter:resolve(nil)
        waiter = nil
        activeProvider = nil
        return true
    end
    return false
end
RegisterNUICallback('inputSubmit', function(data, callback)
    callback({ ok = true })
    local adapter = DT.Modules.Get('input', 'native')
    if adapter then
        adapter:close()
    end
    if waiter then
        waiter:resolve(data and data.values or {})
    end
end)
RegisterNUICallback('inputCancel', function(_, callback)
    callback({ ok = true })
    local adapter = DT.Modules.Get('input', 'native')
    if adapter then
        adapter:close()
    end
    if waiter then
        waiter:resolve(nil)
    end
end)
exports('InputAwait', function(...)
    return DT.Input.Await(...)
end)
exports('InputClose', function(...)
    return DT.Input.Close(...)
end)
