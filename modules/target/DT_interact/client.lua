-- Legacy source-pack Target API. Actions retain its entity-only callback contract.
Target = Target or {}
local function owner()
    return GetInvokingResource() or GetCurrentResourceName()
end
function Target.GetResourceName()
    return 'DT_interact'
end
function Target.FixOptions(list)
    local out = {}
    for _, raw in ipairs(list or {}) do
        local result = {}
        for key, entry in pairs(raw) do
            result[key] = entry
        end
        local action = raw.onSelect or raw.action
        if action then
            result.onSelect = function(data)
                return action(data.entity)
            end
            result.action = nil
        end
        if result.type == 'server' then
            result.serverEvent = result.event
            result.event = nil
        elseif result.type == 'command' then
            result.command = result.event
            result.event = nil
        end
        result.groups = result.groups or result.job
        result.items = result.items or result.item
        out[#out + 1] = result
    end
    return out
end
for _, kind in ipairs({ 'Ped', 'Player', 'Vehicle', 'Object' }) do
    local key = kind
    Target['AddGlobal' .. key] = function(list)
        local handle = exports.DT_interact
        return handle['addGlobal' .. key](handle, Target.FixOptions(list), owner())
    end
    Target['RemoveGlobal' .. key] = function(names)
        local handle = exports.DT_interact
        return handle['removeGlobal' .. key](handle, names, owner())
    end
end
for public, backend in pairs({ LocalEntity = 'LocalEntity', NetworkedEntity = 'Entity', Model = 'Model' }) do
    local key = backend
    Target['Add' .. public] = function(values, list)
        local handle = exports.DT_interact
        return handle['add' .. key](handle, values, Target.FixOptions(list), owner())
    end
    Target['Remove' .. public] = function(values, names)
        local handle = exports.DT_interact
        return handle['remove' .. key](handle, values, names, owner())
    end
end
function Target.AddSphereZone(name, coords, radius, options, debug)
    return exports.DT_interact:addSphereZone(
        { name = name, coords = coords, radius = radius, options = Target.FixOptions(options), debug = debug },
        owner()
    )
end
function Target.AddBoxZone(name, coords, size, heading, options, debug)
    return exports.DT_interact:addBoxZone(
        {
            name = name,
            coords = coords,
            size = size,
            rotation = heading,
            options = Target.FixOptions(options),
            debug = debug,
        },
        owner()
    )
end
function Target.RemoveZone(id)
    return exports.DT_interact:removeZone(id, true, owner())
end
function Target.DisableTargeting(value)
    return exports.DT_interact:disableTargeting(value)
end
