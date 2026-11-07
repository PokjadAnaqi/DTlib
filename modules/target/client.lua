local aliases = { ox = 'ox_target', qb = 'qb-target', interact = 'DT_interact', dt_interact = 'DT_interact' }
local managed = {}
local function resolveAdapter()
    -- Legacy interact mode now selects the external resource; no embedded engine remains.
    if DTConfig.Interaction and DTConfig.Interaction.mode == 'interact' then
        return DT.Modules.Get('target', 'DT_interact')
    end
    return DT.Modules.Resolve(
        'target',
        DTConfig.Adapters.target,
        { 'DT_interact', 'ox_target', 'qb-target', 'sleepless_interact' },
        aliases,
        'none'
    )
end
local function call(methodName, ...)
    local adapter = resolveAdapter()
    if not adapter or type(adapter[methodName]) ~= 'function' then
        return nil, 'unsupported_backend'
    end
    return adapter[methodName](adapter, ...)
end
function DT.Target.Name()
    local adapter = resolveAdapter()
    return adapter and adapter.publicName or 'none'
end
function DT.Target.Available()
    local adapter = resolveAdapter()
    return adapter and adapter.resource ~= 'none'
end
function DT.Target.Disable(state)
    return call('disable', state)
end
DT.Target.DisableTargeting = DT.Target.Disable
function DT.Target.IsActive()
    return call('isActive') == true
end
function DT.Target.GetOptions(...)
    return call('getOptions', ...)
end
function DT.Target.AddGlobal(result)
    return call('addGlobal', result)
end
function DT.Target.RemoveGlobal(count)
    return call('removeGlobal', count)
end
for _, kind in ipairs({ 'Object', 'Ped', 'Player', 'Vehicle' }) do
    DT.Target['AddGlobal' .. kind] = function(result)
        return call('addGlobalKind', kind, result)
    end
    DT.Target['RemoveGlobal' .. kind] = function(count)
        return call('removeGlobalKind', kind, count)
    end
end
function DT.Target.AddEntity(entry, result, data)
    return call('addEntity', entry, result, data)
end
DT.Target.AddLocalEntity = DT.Target.AddEntity
function DT.Target.RemoveEntity(entry, count)
    return call('removeEntity', entry, count)
end
DT.Target.RemoveLocalEntity = DT.Target.RemoveEntity
function DT.Target.AddNetworkEntity(entry, result)
    return call('addNetworkEntity', entry, result)
end
function DT.Target.RemoveNetworkEntity(entry, count)
    return call('removeNetworkEntity', entry, count)
end
function DT.Target.AddModel(methodName, result, data)
    return call('addModel', methodName, result, data)
end
function DT.Target.RemoveModel(methodName, count)
    return call('removeModel', methodName, count)
end
local function addZone(method, data)
    local id = call(method, data or {})
    if id and id ~= false then
        managed[id] = true
        if data and data.name then
            managed[data.name] = true
        end
    end
    return id
end
function DT.Target.AddSphereZone(data)
    return addZone('addSphereZone', data)
end
function DT.Target.AddBoxZone(data)
    return addZone('addBoxZone', data)
end
function DT.Target.AddPolyZone(data)
    return addZone('addPolyZone', data)
end
function DT.Target.ZoneExists(id)
    local result = call('zoneExists', id)
    return result ~= nil and result or managed[id] == true
end
function DT.Target.RemoveZone(id)
    local result = call('removeZone', id)
    if result then
        managed[id] = nil
    end
    return result
end
