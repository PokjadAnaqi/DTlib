local frameworkUtil = DT.FrameworkUtil
local adapter = { resource = 'qb-core', publicName = 'qb' }

local function core()
    local ok, value = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    return ok and value or nil
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:getData()
    local coreObject = core()
    return coreObject and coreObject.Functions.GetPlayerData() or {}
end
function adapter:getJob()
    return frameworkUtil.normalizeGroup(self:getData().job)
end
function adapter:getGang()
    return frameworkUtil.normalizeGroup(self:getData().gang)
end
function adapter:getGroups()
    local groups = {}
    local job, gang = self:getJob(), self:getGang()
    if job and job.name then
        groups[job.name] = job.grade
    end
    if gang and gang.name then
        groups[gang.name] = gang.grade
    end
    return groups
end
function adapter:getMeta(key)
    local data = self:getData()
    local method = data.metadata or data.meta
    return method and method[key] or nil
end
function adapter:getCoords()
    return GetEntityCoords(PlayerPedId())
end
function adapter:getName()
    local data = self:getData()
    local char = data.charinfo or {}
    local name = DTUtils.trim(('%s %s'):format(char.firstname or '', char.lastname or ''))
    return name ~= '' and name or data.name or GetPlayerName(PlayerId())
end

DT.Modules.Register('framework', 'qb-core', adapter)
