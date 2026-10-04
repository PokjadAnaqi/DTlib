local U=DT.FrameworkUtil
local A={resource='ox_core',publicName='ox'}
local function pcallExport(fn) local ok,a,b,c=pcall(fn); if not ok then return nil end; return a,b,c end
local function call(source,method,...)
    local args={...}; return pcallExport(function() return exports.ox_core:CallPlayer(source,method,table.unpack(args)) end)
end
local function pair(source,method,...)
    local a,b=call(source,method,...); if type(a)=='table' and b==nil then return a[1],a[2] end; return a,b
end
local function groupDef(name) return name and GlobalState[('group.%s'):format(name)] or nil end
local function player(source) return pcallExport(function() return exports.ox_core:GetPlayer(source) end) end
local function accountFor(source)
    local p=player(source); if not p or not p.charId then return nil end
    return pcallExport(function() return exports.ox_core:GetCharacterAccount(p.charId) end)
end
local function accountCall(id,method,...)
    if not id then return nil end; local args={...}; return pcallExport(function() return exports.ox_core:CallAccount(id,method,table.unpack(args)) end)
end
local function cashCount(source) if not DTUtils.isStarted('ox_inventory') then return 0 end; local ok,v=pcall(function() return exports.ox_inventory:GetItemCount(source,'money') end); return ok and tonumber(v) or 0 end
local function cashAdd(source,a) if not DTUtils.isStarted('ox_inventory') then return false end; local ok,v=pcall(function() return exports.ox_inventory:AddItem(source,'money',a) end); return ok and v==true end
local function cashRemove(source,a) if not DTUtils.isStarted('ox_inventory') then return false end; local ok,v=pcall(function() return exports.ox_inventory:RemoveItem(source,'money',a) end); return ok and v==true end
local function cashSet(source,a) if not DTUtils.isStarted('ox_inventory') then return false end; local ok,v=pcall(function() return exports.ox_inventory:SetItem(source,'money',a) end); return ok and v~=false end
function A:available() return DTUtils.isStarted(self.resource) end
function A:getJobs() local ok,n=pcall(function() return exports.ox_core:GetGroupsByType('job') end); local out={}; if ok and type(n)=='table' then for i=1,#n do out[n[i]]=groupDef(n[i]) or {name=n[i],type='job'} end end; return out end
function A:getGangs() local ok,n=pcall(function() return exports.ox_core:GetGroupsByType('gang') end); local out={}; if ok and type(n)=='table' then for i=1,#n do out[n[i]]=groupDef(n[i]) or {name=n[i],type='gang'} end end; return out end
function A:getJob(name) return self:getJobs()[name] end
function A:getGang(name) return self:getGangs()[name] end
function A:getVehicles(filter) local ok,v=pcall(function() return exports.ox_core:GetVehicleData(filter) end); return ok and v or {} end
function A:getWeapons() return {} end
function A:getPlayer(source) return player(source) end
function A:getByUserId(id) return pcallExport(function() return exports.ox_core:GetPlayerFromUserId(id) end) end
function A:getByCharacterId(id) return pcallExport(function() return exports.ox_core:GetPlayerFromCharId(id) end) end
function A:getByIdentifier(identifier) return pcallExport(function() return exports.ox_core:GetPlayerFromFilter({identifier=identifier}) end) end
function A:getPlayers() local v=pcallExport(function() return exports.ox_core:GetPlayers() end) or {}; local out={}; for i=1,#v do if v[i].source then out[#out+1]=tonumber(v[i].source) or v[i].source end end; return out end
function A:getPlayersData() return pcallExport(function() return exports.ox_core:GetPlayers() end) or {} end
function A:getIdentifier(source) local p=player(source); return p and (p.stateId or p.identifier) or GetPlayerIdentifierByType(source,'license') end
function A:getUserId(source) local p=player(source); return p and p.userId or nil end
function A:getCharacterId(source) local p=player(source); return p and p.charId or nil end
function A:getStateId(source) local p=player(source); return p and p.stateId or nil end
function A:getName(source) local p=player(source); return call(source,'get','name') or (p and p.username) or GetPlayerName(source) end
function A:getJobFor(source) local n,g=pair(source,'getGroupByType','job'); return n and U.normalizeGroup(groupDef(n),n,g) or nil end
function A:getGangFor(source) local n,g=pair(source,'getGroupByType','gang'); return n and U.normalizeGroup(groupDef(n),n,g) or nil end
function A:getGroups(source) local g=call(source,'getGroups'); return type(g)=='table' and g or {} end
function A:getGroup(source,filter) return pair(source,'getGroup',filter) end
function A:hasGroup(source,filter) local n=self:getGroup(source,filter); return n~=nil and n~=false end
function A:hasPrimaryGroup(source,filter) local active=call(source,'get','activeGroup'); if not active then return false end; local g=self:getGroups(source); return U.filterMatch({[active]=g[active] or 0},filter) end
function A:setJob(source,name,grade) local current=select(1,pair(source,'getGroupByType','job')); if current and current~=name then call(source,'setGroup',current,0) end; return call(source,'setGroup',name,tonumber(grade) or 0)==true end
function A:setJobDuty() return false end
function A:setGang(source,name,grade) local current=select(1,pair(source,'getGroupByType','gang')); if current and current~=name then call(source,'setGroup',current,0) end; return call(source,'setGroup',name,tonumber(grade) or 0)==true end
function A:getMoney(source,t)
    t=t or 'cash'; if t=='cash' or t=='money' then return cashCount(source) end
    if t=='bank' then local a=accountFor(source); local b=a and accountCall(a.accountId,'get','balance'); return tonumber(b) or 0 end; return 0
end
function A:addMoney(source,t,a,r) t=t or 'cash'; if t=='cash' or t=='money' then return cashAdd(source,a) end; if t=='bank' then local x=accountFor(source); local v=x and accountCall(x.accountId,'addBalance',{amount=a,message=r or 'DTlib'}); return type(v)=='table' and v.success==true or v==true end; return false end
function A:removeMoney(source,t,a,r) t=t or 'cash'; if t=='cash' or t=='money' then return cashRemove(source,a) end; if t=='bank' then local x=accountFor(source); local v=x and accountCall(x.accountId,'removeBalance',{amount=a,message=r or 'DTlib'}); return type(v)=='table' and v.success==true or v==true end; return false end
function A:setMoney(source,t,a,r) t=t or 'cash'; if t=='cash' or t=='money' then return cashSet(source,a) end; if t=='bank' then local c=self:getMoney(source,'bank'); if c==a then return true elseif a>c then return self:addMoney(source,'bank',a-c,r) else return self:removeMoney(source,'bank',c-a,r) end end; return false end
function A:getMeta(source,key) return call(source,'get',key) end
function A:setMeta(source,key,value,replicated) call(source,'set',key,value,replicated==true); return true end
function A:getStatus(source,key) return call(source,'getStatus',key) end
function A:setStatus(source,key,v) return call(source,'setStatus',key,v)==true end
function A:addStatus(source,key,v) return call(source,'addStatus',key,v)==true end
function A:removeStatus(source,key,v) return call(source,'removeStatus',key,v)==true end
function A:hasPermission(source,p) local v=call(source,'hasPermission',p); return v==true end
function A:getCoords(source) return call(source,'getCoords') end
function A:save(source) call(source,'save'); return true end
function A:getData(source) local p=player(source); if not p then return {} end; return {source=tonumber(source) or source,identifier=p.identifier,userId=p.userId,charId=p.charId,stateId=p.stateId,name=self:getName(source),job=self:getJobFor(source),gang=self:getGangFor(source),groups=self:getGroups(source),activeGroup=self:getMeta(source,'activeGroup')} end
DT.Modules.Register('framework','ox_core',A)
