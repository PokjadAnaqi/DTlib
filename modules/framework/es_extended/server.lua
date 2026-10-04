local U=DT.FrameworkUtil
local A={resource='es_extended',publicName='esx'}
local function core() local ok,v=pcall(function() return exports.es_extended:getSharedObject() end); return ok and v or nil end
local function player(source)
    local c=core(); if not c then return nil end
    if type(c.Player)=='function' then local ok,p=pcall(c.Player,source); if ok and p then return p end end
    if type(c.GetPlayerFromId)=='function' then local ok,p=pcall(c.GetPlayerFromId,source); if ok then return p end end
end
local function account(t) return (t==nil or t=='cash') and 'money' or t end
function A:available() return DTUtils.isStarted(self.resource) end
function A:getJobs() local c=core(); if c and type(c.GetJobs)=='function' then local ok,v=pcall(c.GetJobs); return ok and v or {} end; return {} end
function A:getGangs() return {} end
function A:getJob(name) return self:getJobs()[name] end
function A:getGang() return nil end
function A:getPlayer(source) return player(source) end
function A:getByIdentifier(identifier)
    local c=core(); if not c then return nil end
    if type(c.Player)=='function' then local ok,p=pcall(c.Player,identifier); if ok and p then return p end end
    if type(c.GetPlayerFromIdentifier)=='function' then local ok,p=pcall(c.GetPlayerFromIdentifier,identifier); if ok then return p end end
end
function A:getPlayers()
    local c=core(); if c and type(c.ExtendedPlayers)=='function' then local ok,v=pcall(c.ExtendedPlayers); if ok and type(v)=='table' then local o={}; for i=1,#v do local s=v[i].source or v[i].playerId; if s then o[#o+1]=tonumber(s) or s end end; if #o>0 then return o end end end
    if c and type(c.GetPlayers)=='function' then local ok,v=pcall(c.GetPlayers); if ok and v then return v end end
    return {}
end
function A:getIdentifier(source) local p=player(source); if p and p.getIdentifier then local ok,v=pcall(p.getIdentifier); if ok and v then return v end end; return p and p.identifier or GetPlayerIdentifierByType(source,'license') end
function A:getName(source) local p=player(source); if p and p.getName then local ok,v=pcall(p.getName); if ok and v then return v end end; return p and p.name or GetPlayerName(source) end
function A:getJobFor(source) local p=player(source); if not p then return nil end; local d=p.job; if p.getJob then local ok,v=pcall(p.getJob); if ok and v then d=v end end; return U.normalizeGroup(d) end
function A:getGangFor() return nil end
function A:getGroups(source) local g={}; local j=self:getJobFor(source); if j and j.name then g[j.name]=j.grade end; local p=player(source); if p and p.getGroup then local ok,v=pcall(p.getGroup); if ok and v then g[v]=math.max(g[v] or 0,0) end end; return g end
function A:setJob(source,name,grade,onDuty) local p=player(source); if not p or not p.setJob then return false end; p.setJob(name,tonumber(grade) or 0,onDuty); return true end
function A:getMoney(source,t) local p=player(source); if p and p.getAccount then local ok,a=pcall(p.getAccount,account(t)); return ok and a and tonumber(a.money) or 0 end; return 0 end
function A:addMoney(source,t,a,r) local p=player(source); if p and p.addAccountMoney then p.addAccountMoney(account(t),a,r or 'DTlib'); return true end; return false end
function A:removeMoney(source,t,a,r) local p=player(source); if p and p.removeAccountMoney then p.removeAccountMoney(account(t),a,r or 'DTlib'); return true end; return false end
function A:setMoney(source,t,a,r) local p=player(source); if p and p.setAccountMoney then p.setAccountMoney(account(t),a,r or 'DTlib'); return true end; return false end
function A:getMeta(source,key) local p=player(source); if p and p.getMeta then local ok,v=pcall(p.getMeta,key); return ok and v or nil end end
function A:setMeta(source,key,value) local p=player(source); if p and p.setMeta then p.setMeta(key,value); return true end; return false end
function A:getCoords(source) local p=player(source); if p and p.getCoords then local ok,v=pcall(p.getCoords,true); if ok and v then return v end end end
function A:save(source) local p=player(source); if p and p.save then p.save(); return true end; return false end
function A:getData(source)
    local p=player(source); if not p then return {} end
    return {source=tonumber(source) or source,identifier=self:getIdentifier(source),name=self:getName(source),job=self:getJobFor(source),groups=self:getGroups(source),accounts=p.getAccounts and p.getAccounts() or p.accounts,metadata=p.getMeta and p.getMeta() or nil}
end
DT.Modules.Register('framework','es_extended',A)
