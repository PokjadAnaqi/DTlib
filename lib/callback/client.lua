local callbacks = {}
local lastFailure = {}
local owners = {}
local pending = {}
local requestId = 0

function DT.Callback.Register(name, callback)
    assert(type(name) == 'string' and name ~= '', 'DT.Callback.Register: name is required')

    local callable = DTUtils.wrapCallable(callback)
    assert(
        callable,
        ('DT.Callback.Register: callback function/funcref is required (received %s)'):format(type(callback))
    )

    callbacks[name] = callable
    owners[name] = GetInvokingResource() or GetCurrentResourceName()
    return true
end

function DT.Callback.Unregister(name)
    if type(name) ~= 'string' or name == '' then
        return false
    end
    local existed = callbacks[name] ~= nil
    callbacks[name] = nil
    owners[name] = nil
    lastFailure[name] = nil
    return existed
end

RegisterNetEvent('DTlib:callback:client:request', function(id, name, ...)
    local callback = callbacks[name]
    if not callback then
        return TriggerServerEvent(
            'DTlib:callback:client:response',
            id,
            false,
            ('unknown_client_callback:%s'):format(name)
        )
    end

    local arguments = table.pack(...)
    CreateThread(function()
        local result = table.pack(pcall(callback, table.unpack(arguments, 1, arguments.n)))
        local ok = result[1]
        if not ok then
            local now = GetGameTimer()
            if not lastFailure[name] or now - lastFailure[name] >= 10000 then
                lastFailure[name] = now
                print(
                    ('[DTlib:callback] side=client name=%s owner=%s source=%s failed: %s'):format(
                        tostring(name),
                        tostring(owners[name]),
                        tostring(GetPlayerServerId(PlayerId())),
                        tostring(result[2])
                    )
                )
            end
            TriggerServerEvent('DTlib:callback:client:response', id, false, tostring(result[2]))
            return
        end
        TriggerServerEvent('DTlib:callback:client:response', id, true, table.unpack(result, 2, result.n))
    end)
end)

RegisterNetEvent('DTlib:callback:server:response', function(id, ok, ...)
    local entry = pending[id]
    if not entry then
        return
    end
    pending[id] = nil
    entry.waiter:resolve({ ok = ok, values = table.pack(...) })
end)

function DT.Callback.Await(name, ...)
    requestId = requestId + 1
    local id = ('%s:%s:%s'):format(GetCurrentResourceName(), GetGameTimer(), requestId)
    local waiter = promise.new()
    local entry = { waiter = waiter, owner = GetInvokingResource() or GetCurrentResourceName() }
    pending[id] = entry
    SetTimeout(DTConfig.CallbackTimeout or 30000, function()
        if pending[id] ~= entry then
            return
        end
        pending[id] = nil
        waiter:resolve({ ok = false, values = table.pack('callback_timeout:' .. tostring(name)) })
    end)
    TriggerServerEvent('DTlib:callback:server:request', id, name, ...)
    local result = Citizen.Await(waiter)
    if not result.ok then
        error(result.values[1] or 'DTlib callback failed', 2)
    end
    return table.unpack(result.values, 1, result.values.n)
end

function DT.Callback.Trigger(name, callback, ...)
    local arguments = table.pack(...)
    local completion = callback ~= nil and DTUtils.wrapCallable(callback) or nil
    if callback ~= nil then
        assert(
            completion,
            ('DT.Callback.Trigger: completion callback must be callable (received %s)'):format(type(callback))
        )
    end

    CreateThread(function()
        local values = table.pack(DT.Callback.Await(name, table.unpack(arguments, 1, arguments.n)))
        if completion then
            completion(table.unpack(values, 1, values.n))
        end
    end)
end

AddEventHandler('onClientResourceStop', function(resource)
    for name, owner in pairs(owners) do
        if owner == resource then
            callbacks[name] = nil
            owners[name] = nil
            lastFailure[name] = nil
        end
    end
    for id, entry in pairs(pending) do
        if resource == GetCurrentResourceName() or entry.owner == resource then
            pending[id] = nil
            entry.waiter:resolve({ ok = false, values = table.pack('callback_resource_stopped:' .. resource) })
        end
    end
end)
