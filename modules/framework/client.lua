local frameworkUtil = DT.FrameworkUtil
local candidates = { 'qbx_core', 'qb-core', 'es_extended', 'ox_core' }
local function adapter()
    return DT.Modules.Resolve('framework', DTConfig.Adapters.framework, candidates, frameworkUtil.aliases, 'standalone')
end

function DT.Framework.Name()
    local provider = adapter()
    return provider and provider.publicName or 'standalone'
end
function DT.Framework.Resource()
    local provider = adapter()
    return provider and provider.resource ~= 'standalone' and provider.resource or nil
end
function DT.Framework.Available(name)
    if not name then
        return DT.Framework.Resource() ~= nil
    end
    name = tostring(name):lower()
    name = frameworkUtil.aliases[name] or name
    return DTUtils.isStarted(name)
end
function DT.Framework.GetVersion()
    local provider = adapter()
    if not provider or provider.resource == 'standalone' then
        return nil
    end
    if provider.resource == 'qbx_core' then
        local ok, value = pcall(function()
            return exports.qbx_core:GetCoreVersion(GetCurrentResourceName())
        end)
        if ok and value then
            return value
        end
    end
    return frameworkUtil.resourceVersion(provider.resource)
end
function DT.Player.GetData()
    local provider = adapter()
    return provider and provider.getData and provider:getData() or {}
end
function DT.Player.GetServerId()
    return GetPlayerServerId(PlayerId())
end
function DT.Player.GetName()
    local provider = adapter()
    return provider and provider.getName and provider:getName() or GetPlayerName(PlayerId())
end
function DT.Player.GetJob()
    local provider = adapter()
    return provider and provider.getJob and provider:getJob() or nil
end
function DT.Player.GetGang()
    local provider = adapter()
    return provider and provider.getGang and provider:getGang() or nil
end
function DT.Player.GetGroups()
    local provider = adapter()
    return provider and provider.getGroups and provider:getGroups() or {}
end
function DT.Player.GetGroup(filter)
    local provider = adapter()
    if provider and provider.getGroup then
        return provider:getGroup(filter)
    end
    local groups = DT.Player.GetGroups()
    if type(filter) == 'string' then
        return groups[filter]
    end
    for name, grade in pairs(groups) do
        if frameworkUtil.filterMatch({ [name] = grade }, filter) then
            return name, grade
        end
    end
end
function DT.Player.HasGroup(filter)
    local provider = adapter()
    if provider and provider.hasGroup then
        return provider:hasGroup(filter)
    end
    return frameworkUtil.filterMatch(DT.Player.GetGroups(), filter)
end
function DT.Player.HasPrimaryGroup(filter)
    local provider = adapter()
    if provider and provider.hasPrimaryGroup then
        return provider:hasPrimaryGroup(filter)
    end
    local groups = {}
    local job, gang = DT.Player.GetJob(), DT.Player.GetGang()
    if job and job.name then
        groups[job.name] = job.grade
    end
    if gang and gang.name then
        groups[gang.name] = gang.grade
    end
    return frameworkUtil.filterMatch(groups, filter)
end
function DT.Player.GetMeta(key)
    local provider = adapter()
    return provider and provider.getMeta and provider:getMeta(key) or nil
end
function DT.Player.GetStatus(status)
    local provider = adapter()
    return provider and provider.getStatus and provider:getStatus(status) or nil
end
function DT.Player.GetCoords()
    local provider = adapter()
    return provider and provider.getCoords and provider:getCoords() or GetEntityCoords(PlayerPedId())
end
function DT.Player.HasPermission(permission)
    local provider = adapter()
    return provider and provider.hasPermission and provider:hasPermission(permission) or false
end
