local callbacks = {}
local clientPending = {}
local requestId = 0

function DT.Callback.Register(name, cb)
    assert(type(name) == 'string' and name ~= '', 'DT.Callback.Register: name is required')

    local callable = DTUtils.wrapCallable(cb)
    assert(callable, ('DT.Callback.Register: callback function/funcref is required (received %s)'):format(type(cb)))

    callbacks[name] = callable
    return true
end

function DT.Callback.Unregister(name)
    if type(name) ~= 'string' or name == '' then return false end
    local existed = callbacks[name] ~= nil
    callbacks[name] = nil
    return existed
end

RegisterNetEvent('DTlib:callback:server:request', function(id, name, ...)
    local src = source
    local cb = callbacks[name]
    if not cb then
        return TriggerClientEvent('DTlib:callback:server:response', src, id, false, ('unknown_server_callback:%s'):format(name))
    end

    local args = {...}
    CreateThread(function()
        local result = table.pack(pcall(cb, src, table.unpack(args)))
        local ok = table.remove(result, 1)
        if not ok then
            TriggerClientEvent('DTlib:callback:server:response', src, id, false, tostring(result[1]))
            return
        end
        TriggerClientEvent('DTlib:callback:server:response', src, id, true, table.unpack(result, 1, result.n - 1))
    end)
end)

RegisterNetEvent('DTlib:callback:client:response', function(id, ok, ...)
    local src = source
    local entry = clientPending[id]
    if not entry or entry.source ~= src then return end
    clientPending[id] = nil
    entry.waiter:resolve({ok = ok, values = table.pack(...)})
end)

function DT.Callback.AwaitClient(source, name, ...)
    requestId = requestId + 1
    local id = ('server:%s:%s:%s'):format(source, os.time(), requestId)
    local waiter = promise.new()
    clientPending[id] = {source = source, waiter = waiter}
    TriggerClientEvent('DTlib:callback:client:request', source, id, name, ...)
    local result = Citizen.Await(waiter)
    if not result.ok then error(result.values[1] or 'DTlib client callback failed', 2) end
    return table.unpack(result.values, 1, result.values.n)
end
