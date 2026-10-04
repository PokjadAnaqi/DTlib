local U = DT.FrameworkUtil
local A = { resource = 'qbx_core', publicName = 'qbx' }
function A:available() return DTUtils.isStarted(self.resource) end
function A:getVersion()
    local ok,v=pcall(function() return exports.qbx_core:GetCoreVersion(GetCurrentResourceName()) end)
    return ok and v or U.resourceVersion(self.resource)
end
function A:getJobs() local ok,v=pcall(function() return exports.qbx_core:GetJobs() end); return ok and v or {} end
function A:getGangs() local ok,v=pcall(function() return exports.qbx_core:GetGangs() end); return ok and v or {} end
function A:getJob(name) local ok,v=pcall(function() return exports.qbx_core:GetJob(name) end); return ok and v or nil end
function A:getGang(name) local ok,v=pcall(function() return exports.qbx_core:GetGang(name) end); return ok and v or nil end
function A:getVehicles(filter) local ok,v=pcall(function() return exports.qbx_core:GetVehiclesByName(filter) end); return ok and v or {} end
function A:getWeapons(filter) local ok,v=pcall(function() return exports.qbx_core:GetWeapons(filter) end); return ok and v or {} end
function A:getPlayer(source) local ok,v=pcall(function() return exports.qbx_core:GetPlayer(source) end); return ok and v or nil end
function A:getByCitizenId(id) local ok,v=pcall(function() return exports.qbx_core:GetPlayerByCitizenId(id) end); return ok and v or nil end
function A:getByUserId(id) local ok,v=pcall(function() return exports.qbx_core:GetPlayerByUserId(id) end); return ok and v or nil end
function A:getByIdentifier(identifier)
    local ok,src=pcall(function() return exports.qbx_core:GetSource(identifier) end)
    return ok and tonumber(src) and tonumber(src)>0 and self:getPlayer(tonumber(src)) or nil
end
function A:getPlayers()
    local out={}; local ok,players=pcall(function() return exports.qbx_core:GetQBPlayers() end)
    if ok and type(players)=='table' then for source in pairs(players) do out[#out+1]=tonumber(source) or source end end
    return out
end
function A:getPlayersData() local ok,v=pcall(function() return exports.qbx_core:GetPlayersData() end); return ok and v or {} end
function A:getIdentifier(source) local p=self:getPlayer(source); return p and p.PlayerData and p.PlayerData.citizenid or nil end
function A:getCitizenId(source) return self:getIdentifier(source) end
function A:getUserId(source)
    local id=GetPlayerIdentifierByType(source,'license'); if not id then return nil end
    local ok,v=pcall(function() return exports.qbx_core:GetUserId(id) end); return ok and v~=0 and v or nil
end
function A:getName(source)
    local p=self:getPlayer(source); if not p or not p.PlayerData then return GetPlayerName(source) end
    local c=p.PlayerData.charinfo or {}; local n=DTUtils.trim(('%s %s'):format(c.firstname or '',c.lastname or ''))
    return n~='' and n or p.PlayerData.name or GetPlayerName(source)
end
function A:getJobFor(source) local p=self:getPlayer(source); return p and U.normalizeGroup(p.PlayerData and p.PlayerData.job) or nil end
function A:getGangFor(source) local p=self:getPlayer(source); return p and U.normalizeGroup(p.PlayerData and p.PlayerData.gang) or nil end
function A:getGroups(source) local ok,v=pcall(function() return exports.qbx_core:GetGroups(source) end); return ok and v or {} end
function A:hasGroup(source,filter) local ok,v=pcall(function() return exports.qbx_core:HasGroup(source,filter) end); return ok and v==true end
function A:hasPrimaryGroup(source,filter) local ok,v=pcall(function() return exports.qbx_core:HasPrimaryGroup(source,filter) end); return ok and v==true end
function A:setJob(source,name,grade,onDuty)
    local ok,v=pcall(function() return exports.qbx_core:SetJob(source,name,tonumber(grade) or 0) end); if not ok or v==false then return false end
    if onDuty~=nil then pcall(function() exports.qbx_core:SetJobDuty(source,onDuty==true) end) end; return true
end
function A:setJobDuty(source,state) local ok,v=pcall(function() return exports.qbx_core:SetJobDuty(source,state==true) end); return ok and v~=false end
function A:setGang(source,name,grade) local ok,v=pcall(function() return exports.qbx_core:SetGang(source,name,tonumber(grade) or 0) end); return ok and v~=false end
function A:getMoney(source,t) local ok,v=pcall(function() return exports.qbx_core:GetMoney(source,t or 'cash') end); return ok and tonumber(v) or 0 end
function A:addMoney(source,t,a,r) local ok,v=pcall(function() return exports.qbx_core:AddMoney(source,t or 'cash',a,r or 'DTlib') end); return ok and v==true end
function A:removeMoney(source,t,a,r) local ok,v=pcall(function() return exports.qbx_core:RemoveMoney(source,t or 'cash',a,r or 'DTlib') end); return ok and v==true end
function A:setMoney(source,t,a,r) local ok,v=pcall(function() return exports.qbx_core:SetMoney(source,t or 'cash',a,r or 'DTlib') end); return ok and v==true end
function A:getMeta(source,key) local ok,v=pcall(function() return exports.qbx_core:GetMetadata(source,key) end); return ok and v or nil end
function A:setMeta(source,key,value) local ok,v=pcall(function() return exports.qbx_core:SetMetadata(source,key,value) end); return ok and v~=false end
function A:save(source) local ok,v=pcall(function() return exports.qbx_core:Save(source) end); return ok and v~=false end
function A:getData(source) local p=self:getPlayer(source); return p and p.PlayerData or {} end
DT.Modules.Register('framework','qbx_core',A)
