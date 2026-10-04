local U = DT.FrameworkUtil
local A = { resource = 'es_extended', publicName = 'esx' }
local function core()
    local ok, value = pcall(function() return exports.es_extended:getSharedObject() end)
    return ok and value or nil
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:getData() local c=core(); return c and c.GetPlayerData and c.GetPlayerData() or {} end
function A:getJob() return U.normalizeGroup(self:getData().job) end
function A:getGang() return nil end
function A:getGroups()
    local groups={}; local data=self:getData(); local job=self:getJob()
    if job and job.name then groups[job.name]=job.grade end
    if data.group then groups[data.group]=0 end
    return groups
end
function A:getMeta(key) local d=self:getData(); local m=d.metadata or d.meta; return m and m[key] or nil end
function A:getCoords() return GetEntityCoords(PlayerPedId()) end
function A:getName() local d=self:getData(); return d.name or GetPlayerName(PlayerId()) end

DT.Modules.Register('framework', 'es_extended', A)
