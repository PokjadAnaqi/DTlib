local adapter = { resource = 'qb-target', publicName = 'qb-target' }
local function wrap(value)
    return DTUtils.wrapCallable(value)
end
local function options(list)
    local out = {}
    for index = 1, #(list or {}) do
        local result = list[index]
        if type(result) == 'table' then
            local event = result.event
            local typ = 'client'
            if result.serverEvent then
                event = result.serverEvent
                typ = 'server'
            elseif result.command then
                event = result.command
                typ = 'command'
            end
            out[#out + 1] = {
                num = result.num or index,
                label = result.label,
                icon = result.icon,
                canInteract = wrap(result.canInteract),
                action = wrap(result.onSelect or result.action),
                event = event,
                type = typ,
                job = result.job or result.groups,
                gang = result.gang,
                item = result.item or result.items,
            }
        end
    end
    return out
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:addGlobalKind(kind, result)
    local payload = { options = options(result), distance = 2.0 }
    if kind == 'Object' then
        exports['qb-target']:AddGlobalObject(payload)
    elseif kind == 'Ped' then
        exports['qb-target']:AddGlobalPed(payload)
    elseif kind == 'Player' then
        exports['qb-target']:AddGlobalPlayer(payload)
    elseif kind == 'Vehicle' then
        exports['qb-target']:AddGlobalVehicle(payload)
    else
        return false
    end
    return true
end
function adapter:removeGlobalKind(kind, count)
    if kind == 'Object' then
        exports['qb-target']:RemoveGlobalObject(count)
    elseif kind == 'Ped' then
        exports['qb-target']:RemoveGlobalPed(count)
    elseif kind == 'Player' then
        exports['qb-target']:RemoveGlobalPlayer(count)
    elseif kind == 'Vehicle' then
        exports['qb-target']:RemoveGlobalVehicle(count)
    else
        return false
    end
    return true
end
function adapter:addEntity(entry, result, data)
    exports['qb-target']:AddTargetEntity(entry, { options = options(result), distance = data or 2.0 })
    return true
end
function adapter:removeEntity(entry, count)
    exports['qb-target']:RemoveTargetEntity(entry, count)
    return true
end
function adapter:addModel(method, result, data)
    exports['qb-target']:AddTargetModel(method, { options = options(result), distance = data or 2.0 })
    return true
end
function adapter:removeModel(method, count)
    exports['qb-target']:RemoveTargetModel(method, count)
    return true
end
function adapter:addSphereZone(data)
    local name = data.name or ('dtlib_sphere_%s'):format(GetGameTimer())
    exports['qb-target']:AddCircleZone(
        name,
        data.coords,
        data.radius or 1.5,
        { name = name, debugPoly = data.debug or false, useZ = data.useZ ~= false },
        { options = options(data.options), distance = data.distance or 2.0 }
    )
    return name
end
function adapter:addBoxZone(data)
    local name = data.name or ('dtlib_box_%s'):format(GetGameTimer())
    local value = data.size or vector3(1.0, 1.0, 1.0)
    exports['qb-target']:AddBoxZone(name, data.coords, value.x, value.y, {
        name = name,
        heading = data.rotation or data.heading or 0.0,
        debugPoly = data.debug or false,
        minZ = data.minZ or (data.coords.z - value.z * 0.5),
        maxZ = data.maxZ or (data.coords.z + value.z * 0.5),
    }, { options = options(data.options), distance = data.distance or 2.0 })
    return name
end
function adapter:addPolyZone(data)
    local name = data.name or ('dtlib_poly_%s'):format(GetGameTimer())
    local pts = {}
    local minZ, maxZ
    for index = 1, #(data.points or {}) do
        pts[index] = vector2(data.points[index].x, data.points[index].y)
        minZ = math.min(minZ or data.points[index].z, data.points[index].z)
        maxZ = math.max(maxZ or data.points[index].z, data.points[index].z)
    end
    local zoneThickness = data.thickness or 4.0
    exports['qb-target']:AddPolyZone(
        name,
        pts,
        {
            name = name,
            debugPoly = data.debug or false,
            minZ = data.minZ or ((minZ or 0) - zoneThickness * 0.5),
            maxZ = data.maxZ or ((maxZ or 0) + zoneThickness * 0.5),
        },
        { options = options(data.options), distance = data.distance or 2.0 }
    )
    return name
end
function adapter:removeZone(id)
    exports['qb-target']:RemoveZone(id)
    return true
end
DT.Modules.Register('target', 'qb-target', adapter)
