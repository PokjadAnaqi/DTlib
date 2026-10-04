-- Client-side FiveM/Cfx helpers.

function DT.State.GetLocal(key)
    local state = LocalPlayer.state
    if key == nil then return state end
    return state[key]
end

function DT.State.SetLocal(key, value, replicated)
    if key == nil then return false end
    LocalPlayer.state:set(key, value, replicated == true)
    return true
end

function DT.State.GetPlayer(serverId, key)
    serverId = tonumber(serverId)
    if not serverId then return nil end
    -- Cfx player state bags are addressed by server ID/source on both sides.
    local state = Player(serverId).state
    if key == nil then return state end
    return state[key]
end

function DT.State.GetEntity(entity, key)
    if not entity or entity == 0 then return nil end
    local state = Entity(entity).state
    if key == nil then return state end
    return state[key]
end

function DT.State.SetEntity(entity, key, value, replicated)
    if not entity or entity == 0 or key == nil then return false end
    Entity(entity).state:set(key, value, replicated == true)
    return true
end

function DT.State.GetGlobal(key)
    if key == nil then return GlobalState end
    return GlobalState[key]
end

function DT.State.OnChange(keyFilter, bagFilter, callback)
    if type(callback) ~= 'function' then return nil end
    return AddStateBagChangeHandler(keyFilter, bagFilter, callback)
end

function DT.State.RemoveHandler(cookie)
    if cookie == nil or type(RemoveStateBagChangeHandler) ~= 'function' then return false end
    RemoveStateBagChangeHandler(cookie)
    return true
end

function DT.Entity.GetNetworkId(entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return nil end
    return NetworkGetNetworkIdFromEntity(entity)
end

function DT.Entity.FromNetworkId(netId)
    netId = tonumber(netId)
    if not netId or not NetworkDoesEntityExistWithNetworkId(netId) then return 0 end
    return NetworkGetEntityFromNetworkId(netId)
end

function DT.Entity.Exists(entity)
    return entity ~= nil and entity ~= 0 and DoesEntityExist(entity)
end

function DT.Entity.RequestControl(entity, timeout)
    if not DT.Entity.Exists(entity) then return false end
    if not NetworkGetEntityIsNetworked(entity) then return true end
    if NetworkHasControlOfEntity(entity) then return true end

    timeout = tonumber(timeout) or 1500
    local expires = GetGameTimer() + timeout
    repeat
        NetworkRequestControlOfEntity(entity)
        Wait(0)
    until NetworkHasControlOfEntity(entity) or GetGameTimer() >= expires

    return NetworkHasControlOfEntity(entity)
end

function DT.Entity.Delete(entity, requestControl)
    if not DT.Entity.Exists(entity) then return false end
    if requestControl ~= false and not DT.Entity.RequestControl(entity) then return false end
    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
    return not DoesEntityExist(entity)
end

function DT.OneSync.Enabled()
    -- Client capability check only; no server.cfg/convar setting is required by DTlib.
    return type(NetworkGetEntityIsNetworked) == 'function'
        and type(NetworkGetNetworkIdFromEntity) == 'function'
end

function DT.OneSync.Mode()
    return DT.OneSync.Enabled() and 'enabled' or 'unavailable'
end
