local frameworkUtil = DT.FrameworkUtil
local adapter = { resource = 'ox_core', publicName = 'ox' }
local function call(method, ...)
    local arguments = { ... }
    local ok, provider, secondary, coreObject = pcall(function()
        return exports.ox_core:CallPlayer(method, table.unpack(arguments))
    end)
    if not ok then
        return nil
    end
    return provider, secondary, coreObject
end
local function pair(method, ...)
    local result, secondary = call(method, ...)
    if type(result) == 'table' and secondary == nil then
        return result[1], result[2]
    end
    return result, secondary
end
local function groupDef(name)
    local ok, details = pcall(function()
        return GlobalState[('group.%s'):format(name)]
    end)
    return ok and details or nil
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:getData()
    local ok, data = pcall(function()
        return exports.ox_core:GetPlayer()
    end)
    if not ok or type(data) ~= 'table' then
        data = {}
    end
    data.name = call('get', 'name')
    data.activeGroup = call('get', 'activeGroup')
    data.groups = call('getGroups') or {}
    return data
end
function adapter:getJob()
    local count, groupData = pair('getGroupByType', 'job')
    return count and frameworkUtil.normalizeGroup(groupDef(count), count, groupData) or nil
end
function adapter:getGang()
    local count, groupData = pair('getGroupByType', 'gang')
    return count and frameworkUtil.normalizeGroup(groupDef(count), count, groupData) or nil
end
function adapter:getGroups()
    local result = call('getGroups')
    return type(result) == 'table' and result or {}
end
function adapter:getGroup(filter)
    return pair('getGroup', filter)
end
function adapter:hasGroup(filter)
    local groupData = self:getGroup(filter)
    return groupData ~= nil and groupData ~= false
end
function adapter:hasPrimaryGroup(filter)
    local active = call('get', 'activeGroup')
    if not active then
        return false
    end
    local groups = self:getGroups()
    return frameworkUtil.filterMatch({ [active] = groups[active] or 0 }, filter)
end
function adapter:getMeta(key)
    return call('get', key)
end
function adapter:getStatus(status)
    return call('getStatus', status)
end
function adapter:getCoords()
    return call('getCoords') or GetEntityCoords(PlayerPedId())
end
function adapter:hasPermission(permission)
    local result = call('hasPermission', permission)
    return result == true
end
function adapter:getName()
    return call('get', 'name') or GetPlayerName(PlayerId())
end

DT.Modules.Register('framework', 'ox_core', adapter)
