local adapter = { resource = 'ox_target', publicName = 'ox_target' }
local function wrap(value)
    return DTUtils.wrapCallable(value)
end
local function options(list)
    local out = {}
    for index = 1, #(list or {}) do
        local result = list[index]
        if type(result) == 'table' then
            out[#out + 1] = {
                name = result.name,
                label = result.label,
                icon = result.icon,
                iconColor = result.iconColor,
                distance = result.distance,
                bones = result.bones,
                offset = result.offset,
                offsetAbsolute = result.offsetAbsolute,
                offsetSize = result.offsetSize,
                groups = result.groups or result.job or result.gang,
                items = result.items or result.item,
                anyItem = result.anyItem,
                canInteract = wrap(result.canInteract),
                menuName = result.menuName,
                openMenu = result.openMenu,
                onSelect = wrap(result.onSelect or result.action),
                export = result.export,
                event = result.event,
                serverEvent = result.serverEvent,
                command = result.command,
            }
        end
    end
    return out
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:disable(state)
    exports.ox_target:disableTargeting(state == true)
    return true
end
function adapter:isActive()
    local ok, value = pcall(function()
        return exports.ox_target:isActive()
    end)
    return ok and value == true
end
function adapter:getOptions(...)
    local arguments = { ... }
    local ok, value = pcall(function()
        return exports.ox_target:getTargetOptions(table.unpack(arguments))
    end)
    return ok and value or nil
end
function adapter:addGlobal(result)
    exports.ox_target:addGlobalOption(options(result))
    return true
end
function adapter:removeGlobal(count)
    exports.ox_target:removeGlobalOption(count)
    return true
end
function adapter:addGlobalKind(kind, result)
    result = options(result)
    if kind == 'Object' then
        exports.ox_target:addGlobalObject(result)
    elseif kind == 'Ped' then
        exports.ox_target:addGlobalPed(result)
    elseif kind == 'Player' then
        exports.ox_target:addGlobalPlayer(result)
    elseif kind == 'Vehicle' then
        exports.ox_target:addGlobalVehicle(result)
    else
        return false
    end
    return true
end
function adapter:removeGlobalKind(kind, count)
    if kind == 'Object' then
        exports.ox_target:removeGlobalObject(count)
    elseif kind == 'Ped' then
        exports.ox_target:removeGlobalPed(count)
    elseif kind == 'Player' then
        exports.ox_target:removeGlobalPlayer(count)
    elseif kind == 'Vehicle' then
        exports.ox_target:removeGlobalVehicle(count)
    else
        return false
    end
    return true
end
function adapter:addEntity(entry, result)
    exports.ox_target:addLocalEntity(entry, options(result))
    return true
end
function adapter:removeEntity(entry, count)
    exports.ox_target:removeLocalEntity(entry, count)
    return true
end
function adapter:addNetworkEntity(entry, result)
    exports.ox_target:addEntity(entry, options(result))
    return true
end
function adapter:removeNetworkEntity(entry, count)
    exports.ox_target:removeEntity(entry, count)
    return true
end
function adapter:addModel(method, result)
    exports.ox_target:addModel(method, options(result))
    return true
end
function adapter:removeModel(method, count)
    exports.ox_target:removeModel(method, count)
    return true
end
function adapter:addSphereZone(data)
    return exports.ox_target:addSphereZone({
        coords = data.coords,
        name = data.name,
        radius = data.radius or 1.5,
        debug = data.debug or false,
        drawSprite = data.drawSprite,
        options = options(data.options),
    })
end
function adapter:addBoxZone(data)
    return exports.ox_target:addBoxZone({
        coords = data.coords,
        name = data.name,
        size = data.size or vector3(1.0, 1.0, 1.0),
        rotation = data.rotation or data.heading or 0.0,
        debug = data.debug or false,
        drawSprite = data.drawSprite,
        options = options(data.options),
    })
end
function adapter:addPolyZone(data)
    return exports.ox_target:addPolyZone({
        points = data.points,
        name = data.name,
        thickness = data.thickness or 4.0,
        debug = data.debug or false,
        drawSprite = data.drawSprite,
        options = options(data.options),
    })
end
function adapter:zoneExists(id)
    local ok, value = pcall(function()
        return exports.ox_target:zoneExists(id)
    end)
    return ok and value == true
end
function adapter:removeZone(id)
    exports.ox_target:removeZone(id)
    return true
end
DT.Modules.Register('target', 'ox_target', adapter)
