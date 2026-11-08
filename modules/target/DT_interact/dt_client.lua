local adapter = { resource = 'DT_interact', publicName = 'DT_interact' }
local function owner()
    return GetInvokingResource() or GetCurrentResourceName()
end
local function options(value)
    local out = {}
    if value and value.label then
        value = { value }
    end
    for _, raw in ipairs(value or {}) do
        local result = {}
        for key, entry in pairs(raw) do
            result[key] = entry
        end
        result.onSelect = DTUtils.wrapCallable(raw.onSelect or raw.action)
        result.canInteract = DTUtils.wrapCallable(raw.canInteract)
        out[#out + 1] = result
    end
    return out
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:disable(state)
    return exports.DT_interact:disableTargeting(state == true)
end
function adapter:isActive()
    return exports.DT_interact:isActive()
end
function adapter:getOptions(...)
    return exports.DT_interact:getTargetOptions(...)
end
function adapter:addGlobal(result)
    return exports.DT_interact:addGlobalOption(options(result), owner())
end
function adapter:removeGlobal(count)
    return exports.DT_interact:removeGlobalOption(count, owner())
end
function adapter:addGlobalKind(kind, result)
    local handle = exports.DT_interact
    return handle['addGlobal' .. kind](handle, options(result), owner())
end
function adapter:removeGlobalKind(kind, count)
    local handle = exports.DT_interact
    return handle['removeGlobal' .. kind](handle, count, owner())
end
function adapter:addEntity(entry, result, data)
    local list = options(result)
    for _, entryValue in ipairs(list) do
        entryValue.distance = entryValue.distance or data
    end
    return exports.DT_interact:addLocalEntity(entry, list, owner())
end
function adapter:removeEntity(entry, count)
    return exports.DT_interact:removeLocalEntity(entry, count, owner())
end
function adapter:addNetworkEntity(entry, result)
    return exports.DT_interact:addEntity(entry, options(result), owner())
end
function adapter:removeNetworkEntity(entry, count)
    return exports.DT_interact:removeEntity(entry, count, owner())
end
function adapter:addModel(method, result, data)
    local list = options(result)
    for _, entry in ipairs(list) do
        entry.distance = entry.distance or data
    end
    return exports.DT_interact:addModel(method, list, owner())
end
function adapter:removeModel(method, count)
    return exports.DT_interact:removeModel(method, count, owner())
end
for public in pairs({ Sphere = true, Box = true, Poly = true }) do
    local name = public
    adapter['add' .. name .. 'Zone'] = function(_, data)
        local copy = {}
        for key, entry in pairs(data) do
            copy[key] = entry
        end
        copy.options = options(data.options)
        local handle = exports.DT_interact
        return handle['add' .. name .. 'Zone'](handle, copy, owner())
    end
end
function adapter:zoneExists(id)
    return exports.DT_interact:zoneExists(id)
end
function adapter:removeZone(id)
    return exports.DT_interact:removeZone(id, true, owner())
end
DT.Modules.Register('target', 'DT_interact', adapter)
