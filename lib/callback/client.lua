local callbacks = {}
local owners = {}
local pending = {}
local requestId = 0

function DT.Callback.Register(name, cb)
    assert(type(name) == 'string' and name ~= '', 'DT.Callback.Register: name is required')

    local callable = DTUtils.wrapCallable(cb)
    assert(callable, ('DT.Callback.Register: callback function/funcref is required (received %s)'):format(type(cb)))

    callbacks[name] = callable
    owners[name] = GetInvokingResource() or GetCurrentResourceName()
    return true
end

function DT.Callback.Unregister(name)
    if type(name) ~= 'string' or name == '' then return false end
    local existed = callbacks[name] ~= nil
    callbacks[name] = nil
    owners[name] = nil
    return existed
end

RegisterNetEvent('DTlib:callback:client:request', function(id, name, ...)
    local cb = callbacks[name]
    if not cb then
        return TriggerServerEvent('DTlib:callback:client:response', id, false, ('unknown_client_callback:%s'):format(name))
    end

    local args = table.pack(...)
    CreateThread(function()
        local result = table.pack(pcall(cb, table.unpack(args, 1, args.n)))
        local ok = result[1]
        if not ok then
            TriggerServerEvent('DTlib:callback:client:response', id, false, tostring(result[2]))
            return
        end
        TriggerServerEvent('DTlib:callback:client:response', id, true, table.unpack(result, 2, result.n))
    end)
end)

RegisterNetEvent('DTlib:callback:server:response', function(id, ok, ...)
    local entry = pending[id]
    if not entry then return end
    pending[id] = nil
    entry.waiter:resolve({ok = ok, values = table.pack(...)})
end)

function DT.Callback.Await(name, ...)
    requestId = requestId + 1
    local id = ('%s:%s:%s'):format(GetCurrentResourceName(), GetGameTimer(), requestId)
    local waiter = promise.new()
    local entry={waiter=waiter,owner=GetInvokingResource() or GetCurrentResourceName()}
    pending[id] = entry
    SetTimeout(DTConfig.CallbackTimeout or 30000,function()
        if pending[id]~=entry then return end
        pending[id]=nil;waiter:resolve({ok=false,values=table.pack('callback_timeout:'..tostring(name))})
    end)
    TriggerServerEvent('DTlib:callback:server:request', id, name, ...)
    local result = Citizen.Await(waiter)
    if not result.ok then error(result.values[1] or 'DTlib callback failed', 2) end
    return table.unpack(result.values, 1, result.values.n)
end

function DT.Callback.Trigger(name, cb, ...)
    local args = table.pack(...)
    local completion = cb ~= nil and DTUtils.wrapCallable(cb) or nil
    if cb ~= nil then
        assert(completion, ('DT.Callback.Trigger: completion callback must be callable (received %s)'):format(type(cb)))
    end

    CreateThread(function()
        local values = table.pack(DT.Callback.Await(name, table.unpack(args, 1, args.n)))
        if completion then completion(table.unpack(values, 1, values.n)) end
    end)
end

AddEventHandler('onClientResourceStop',function(resource)
    for name,owner in pairs(owners) do if owner==resource then callbacks[name]=nil;owners[name]=nil end end
    for id,entry in pairs(pending) do
        if resource==GetCurrentResourceName() or entry.owner==resource then
            pending[id]=nil;entry.waiter:resolve({ok=false,values=table.pack('callback_resource_stopped:'..resource)})
        end
    end
end)
