-- Native FiveM/Cfx helpers kept behind the DT namespace so DT resources do not
-- need to duplicate state-bag, routing-bucket, identifier, and OneSync glue.

function DT.Ace.Allowed(source, ace)
    if source == 0 then return true end
    if type(source) ~= 'number' or type(ace) ~= 'string' then return false end
    return IsPlayerAceAllowed(source, ace)
end

DT.Ace.Has = DT.Ace.Allowed

function DT.State.GetPlayer(source, key)
    if not source then return nil end
    local state = Player(source).state
    if key == nil then return state end
    return state[key]
end

function DT.State.SetPlayer(source, key, value, replicated)
    if not source or key == nil then return false end
    Player(source).state:set(key, value, replicated ~= false)
    return true
end

function DT.State.GetEntity(entity, key)
    if not entity or entity == 0 then return nil end
    local state = Entity(entity).state
    if key == nil then return state end
    return state[key]
end

function DT.State.SetEntity(entity, key, value, replicated)
    if not entity or entity == 0 or key == nil then return false end
    Entity(entity).state:set(key, value, replicated ~= false)
    return true
end

function DT.State.GetGlobal(key)
    if key == nil then return GlobalState end
    return GlobalState[key]
end

function DT.State.SetGlobal(key, value)
    if key == nil then return false end
    GlobalState[key] = value
    return true
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

function DT.Routing.GetPlayer(source)
    return GetPlayerRoutingBucket(source)
end

function DT.Routing.SetPlayer(source, bucket)
    source, bucket = tonumber(source), tonumber(bucket)
    if not source or not bucket then return false end
    SetPlayerRoutingBucket(source, bucket)
    return true
end

function DT.Routing.GetEntity(entity)
    if not entity or entity == 0 then return nil end
    return GetEntityRoutingBucket(entity)
end

function DT.Routing.SetEntity(entity, bucket)
    bucket = tonumber(bucket)
    if not entity or entity == 0 or not bucket then return false end
    SetEntityRoutingBucket(entity, bucket)
    return true
end

function DT.Routing.SetLockdown(bucket, mode)
    bucket = tonumber(bucket)
    if not bucket then return false end
    mode = tostring(mode or 'inactive'):lower()
    if mode ~= 'strict' and mode ~= 'relaxed' and mode ~= 'inactive' and mode ~= 'full' then return false end
    SetRoutingBucketEntityLockdownMode(bucket, mode)
    return true
end

function DT.Routing.SetPopulation(bucket, enabled)
    bucket = tonumber(bucket)
    if not bucket then return false end
    SetRoutingBucketPopulationEnabled(bucket, enabled == true)
    return true
end

function DT.Entity.GetNetworkId(entity)
    if not entity or entity == 0 then return nil end
    return NetworkGetNetworkIdFromEntity(entity)
end

function DT.Entity.FromNetworkId(netId)
    netId = tonumber(netId)
    if not netId then return 0 end
    return NetworkGetEntityFromNetworkId(netId)
end

function DT.Entity.Exists(entity)
    return entity ~= nil and entity ~= 0 and DoesEntityExist(entity)
end

function DT.Entity.Delete(entity)
    if not DT.Entity.Exists(entity) then return false end
    DeleteEntity(entity)
    return not DoesEntityExist(entity)
end

function DT.OneSync.Enabled()
    -- Avoid config/convar coupling. Routing-bucket natives are the DTlib capability gate.
    return type(GetPlayerRoutingBucket) == 'function'
        and type(SetPlayerRoutingBucket) == 'function'
        and type(SetRoutingBucketEntityLockdownMode) == 'function'
end

function DT.OneSync.Mode()
    return DT.OneSync.Enabled() and 'enabled' or 'unavailable'
end

function DT.OneSync.CreateVehicle(model, vehicleType, coords, heading)
    if type(coords) ~= 'vector3' and type(coords) ~= 'table' then return 0 end
    local hash = type(model) == 'number' and model or joaat(model)
    return CreateVehicleServerSetter(
        hash,
        vehicleType or 'automobile',
        coords.x + 0.0,
        coords.y + 0.0,
        coords.z + 0.0,
        tonumber(heading) or 0.0
    )
end
