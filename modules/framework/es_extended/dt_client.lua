local frameworkUtil = DT.FrameworkUtil
local adapter = { resource = 'es_extended', publicName = 'esx' }
local function core()
    local ok, value = pcall(function()
        return exports.es_extended:getSharedObject()
    end)
    return ok and value or nil
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:getData()
    local coreObject = core()
    return coreObject and coreObject.GetPlayerData and coreObject.GetPlayerData() or {}
end
function adapter:getJob()
    return frameworkUtil.normalizeGroup(self:getData().job)
end
function adapter:getGang()
    return nil
end
function adapter:getGroups()
    local groups = {}
    local data = self:getData()
    local job = self:getJob()
    if job and job.name then
        groups[job.name] = job.grade
    end
    if data.group then
        groups[data.group] = 0
    end
    return groups
end
function adapter:getMeta(key)
    local details = self:getData()
    local method = details.metadata or details.meta
    return method and method[key] or nil
end
function adapter:getCoords()
    return GetEntityCoords(PlayerPedId())
end
function adapter:getName()
    local details = self:getData()
    return details.name or GetPlayerName(PlayerId())
end

DT.Modules.Register('framework', 'es_extended', adapter)
