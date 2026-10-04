local U = DT.FrameworkUtil
local A = { resource = 'qb-core', publicName = 'qb' }

local function core()
    local ok, value = pcall(function() return exports['qb-core']:GetCoreObject() end)
    return ok and value or nil
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:getData() local c = core(); return c and c.Functions.GetPlayerData() or {} end
function A:getJob() return U.normalizeGroup(self:getData().job) end
function A:getGang() return U.normalizeGroup(self:getData().gang) end
function A:getGroups()
    local groups = {}; local job, gang = self:getJob(), self:getGang()
    if job and job.name then groups[job.name] = job.grade end
    if gang and gang.name then groups[gang.name] = gang.grade end
    return groups
end
function A:getMeta(key) local data=self:getData(); local m=data.metadata or data.meta; return m and m[key] or nil end
function A:getCoords() return GetEntityCoords(PlayerPedId()) end
function A:getName()
    local data=self:getData(); local char=data.charinfo or {}
    local name=DTUtils.trim(('%s %s'):format(char.firstname or '', char.lastname or ''))
    return name ~= '' and name or data.name or GetPlayerName(PlayerId())
end

DT.Modules.Register('framework', 'qb-core', A)
