local U=DT.FrameworkUtil
local A={resource='qb-core',publicName='qb'}
local function core() local ok,v=pcall(function() return exports['qb-core']:GetCoreObject() end); return ok and v or nil end
function A:available() return DTUtils.isStarted(self.resource) end
function A:getJobs() local c=core(); return c and c.Shared and c.Shared.Jobs or {} end
function A:getGangs() local c=core(); return c and c.Shared and c.Shared.Gangs or {} end
function A:getJob(name) return self:getJobs()[name] end
function A:getGang(name) return self:getGangs()[name] end
function A:getVehicles(filter) local c=core(); local v=c and c.Shared and c.Shared.Vehicles or {}; return filter and v[filter] or v end
function A:getWeapons(filter) local c=core(); local v=c and c.Shared and c.Shared.Weapons or {}; return filter and v[filter] or v end
function A:getPlayer(source) local c=core(); return c and c.Functions.GetPlayer(source) or nil end
function A:getByCitizenId(id) local c=core(); return c and c.Functions.GetPlayerByCitizenId and c.Functions.GetPlayerByCitizenId(id) or nil end
function A:getPlayers() local c=core(); return c and c.Functions.GetPlayers and c.Functions.GetPlayers() or {} end
function A:getIdentifier(source) local p=self:getPlayer(source); return p and p.PlayerData and p.PlayerData.citizenid or nil end
function A:getCitizenId(source) return self:getIdentifier(source) end
function A:getName(source)
    local p=self:getPlayer(source); if not p or not p.PlayerData then return GetPlayerName(source) end
    local c=p.PlayerData.charinfo or {}; local n=DTUtils.trim(('%s %s'):format(c.firstname or '',c.lastname or ''))
    return n~='' and n or p.PlayerData.name or GetPlayerName(source)
end
function A:getJobFor(source) local p=self:getPlayer(source); return p and U.normalizeGroup(p.PlayerData and p.PlayerData.job) or nil end
function A:getGangFor(source) local p=self:getPlayer(source); return p and U.normalizeGroup(p.PlayerData and p.PlayerData.gang) or nil end
function A:getGroups(source)
    local g={}; local j=self:getJobFor(source); local a=self:getGangFor(source); if j and j.name then g[j.name]=j.grade end; if a and a.name then g[a.name]=a.grade end; return g
end
function A:setJob(source,name,grade,onDuty)
    local p=self:getPlayer(source); if not p or not p.Functions or not p.Functions.SetJob then return false end
    local r=p.Functions.SetJob(name,tonumber(grade) or 0); if onDuty~=nil and p.Functions.SetJobDuty then p.Functions.SetJobDuty(onDuty==true) end; return r~=false
end
function A:setJobDuty(source,state) local p=self:getPlayer(source); return p and p.Functions and p.Functions.SetJobDuty and p.Functions.SetJobDuty(state==true)~=false or false end
function A:setGang(source,name,grade) local p=self:getPlayer(source); return p and p.Functions and p.Functions.SetGang and p.Functions.SetGang(name,tonumber(grade) or 0)~=false or false end
function A:getMoney(source,t) local p=self:getPlayer(source); return p and p.PlayerData and p.PlayerData.money and tonumber(p.PlayerData.money[t or 'cash']) or 0 end
function A:addMoney(source,t,a,r) local p=self:getPlayer(source); return p and p.Functions and p.Functions.AddMoney and p.Functions.AddMoney(t or 'cash',a,r or 'DTlib')~=false or false end
function A:removeMoney(source,t,a,r) local p=self:getPlayer(source); return p and p.Functions and p.Functions.RemoveMoney and p.Functions.RemoveMoney(t or 'cash',a,r or 'DTlib')~=false or false end
function A:setMoney(source,t,a,r) local p=self:getPlayer(source); return p and p.Functions and p.Functions.SetMoney and p.Functions.SetMoney(t or 'cash',a,r or 'DTlib')~=false or false end
function A:getMeta(source,key) local p=self:getPlayer(source); return p and p.PlayerData and p.PlayerData.metadata and p.PlayerData.metadata[key] or nil end
function A:setMeta(source,key,value) local p=self:getPlayer(source); if p and p.Functions and p.Functions.SetMetaData then p.Functions.SetMetaData(key,value); return true end; return false end
function A:save(source) local p=self:getPlayer(source); if p and p.Functions and p.Functions.Save then p.Functions.Save(); return true end; return false end
function A:getData(source) local p=self:getPlayer(source); return p and p.PlayerData or {} end
DT.Modules.Register('framework','qb-core',A)
