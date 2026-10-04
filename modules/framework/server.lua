local U=DT.FrameworkUtil
local candidates={'qbx_core','qb-core','es_extended','ox_core'}
local function A() return DT.Modules.Resolve('framework',DTConfig.Adapters.framework,candidates,U.aliases,'standalone') end
local function call(method,...)
    local a=A(); if not a or type(a[method])~='function' then return nil,'unsupported_backend' end
    return a[method](a,...)
end
function DT.Framework.Name() local a=A(); return a and a.publicName or 'standalone' end
function DT.Framework.Resource() local a=A(); return a and a.resource~='standalone' and a.resource or nil end
function DT.Framework.Available(name) if not name then return DT.Framework.Resource()~=nil end; name=tostring(name):lower(); name=U.aliases[name] or name; return DTUtils.isStarted(name) end
function DT.Framework.GetVersion() local a=A(); if not a or a.resource=='standalone' then return nil end; return a.getVersion and a:getVersion() or U.resourceVersion(a.resource) end
function DT.Framework.GetJobs() return call('getJobs') or {} end
function DT.Framework.GetGangs() return call('getGangs') or {} end
function DT.Framework.GetJob(name) if not name then return nil end; local v=call('getJob',name); if v~=nil then return v end; return DT.Framework.GetJobs()[name] end
function DT.Framework.GetGang(name) if not name then return nil end; local v=call('getGang',name); if v~=nil then return v end; return DT.Framework.GetGangs()[name] end
function DT.Framework.GetVehicles(filter) return call('getVehicles',filter) or {} end
function DT.Framework.GetWeapons(filter) return call('getWeapons',filter) or {} end
function DT.Player.Get(source) return call('getPlayer',source) end
function DT.Player.GetByCitizenId(id) return call('getByCitizenId',id) end
function DT.Player.GetByUserId(id) return call('getByUserId',id) end
function DT.Player.GetByCharacterId(id) return call('getByCharacterId',id) end
function DT.Player.GetByIdentifier(id) return call('getByIdentifier',id) end
function DT.Player.GetPlayers() local v=call('getPlayers'); if type(v)=='table' and #v>0 then return v end; local o={}; for _,s in ipairs(GetPlayers()) do o[#o+1]=tonumber(s) or s end; return o end
function DT.Player.GetPlayersData() local v=call('getPlayersData'); if type(v)=='table' then return v end; local o={}; for _,s in ipairs(DT.Player.GetPlayers()) do local d=DT.Player.GetData(s); if d then o[#o+1]=d end end; return o end
function DT.Player.GetIdentifiers(source) return U.playerIdentifiers(source) end
function DT.Player.GetIdentifierByType(source,t) t=t or 'license'; local ok,v=pcall(GetPlayerIdentifierByType,source,t); return ok and v or DT.Player.GetIdentifiers(source)[t] end
function DT.Player.GetLicenseIdentifier(source) return DT.Player.GetIdentifierByType(source,'license2') or DT.Player.GetIdentifierByType(source,'license') end
function DT.Player.GetIdentifier(source) return call('getIdentifier',source) or DT.Player.GetIdentifierByType(source,'license') end
function DT.Player.GetCitizenId(source) return call('getCitizenId',source) end
function DT.Player.GetUserId(source) return call('getUserId',source) end
function DT.Player.GetCharacterId(source) return call('getCharacterId',source) end
function DT.Player.GetStateId(source) return call('getStateId',source) end
function DT.Player.GetName(source) return call('getName',source) or GetPlayerName(source) end
function DT.Player.GetJob(source) return call('getJobFor',source) end
function DT.Player.GetGang(source) return call('getGangFor',source) end
function DT.Player.GetGroups(source) return call('getGroups',source) or {} end
function DT.Player.GetGroup(source,filter)
    local v,b=call('getGroup',source,filter); if v~=nil then return v,b end
    local g=DT.Player.GetGroups(source); if type(filter)=='string' then return g[filter] end; for name,grade in pairs(g) do if U.filterMatch({[name]=grade},filter) then return name,grade end end
end
function DT.Player.HasGroup(source,filter) local v=call('hasGroup',source,filter); if v~=nil and v~='unsupported_backend' then return v==true end; return U.filterMatch(DT.Player.GetGroups(source),filter) end
function DT.Player.HasPrimaryGroup(source,filter)
    local v=call('hasPrimaryGroup',source,filter); if v~=nil and v~='unsupported_backend' then return v==true end
    local g={}; local j,a=DT.Player.GetJob(source),DT.Player.GetGang(source); if j and j.name then g[j.name]=j.grade end; if a and a.name then g[a.name]=a.grade end; return U.filterMatch(g,filter)
end
function DT.Player.SetJob(source,name,grade,onDuty) return call('setJob',source,name,grade,onDuty)==true end
function DT.Player.SetJobDuty(source,state) return call('setJobDuty',source,state)==true end
function DT.Player.SetGang(source,name,grade) return call('setGang',source,name,grade)==true end
function DT.Player.GetMoney(source,t) return tonumber(call('getMoney',source,t) or 0) or 0 end
function DT.Player.AddMoney(source,t,a,r) a=tonumber(a) or 0; if a<=0 then return false end; return call('addMoney',source,t,a,r)==true end
function DT.Player.RemoveMoney(source,t,a,r) a=tonumber(a) or 0; if a<=0 then return false end; return call('removeMoney',source,t,a,r)==true end
function DT.Player.SetMoney(source,t,a,r) a=math.max(0,tonumber(a) or 0); return call('setMoney',source,t,a,r)==true end
function DT.Player.GetMeta(source,key) return call('getMeta',source,key) end
function DT.Player.SetMeta(source,key,value,replicated) return call('setMeta',source,key,value,replicated)==true end
function DT.Player.GetStatus(source,key) return call('getStatus',source,key) end
function DT.Player.SetStatus(source,key,v) return call('setStatus',source,key,v)==true end
function DT.Player.AddStatus(source,key,v) return call('addStatus',source,key,v)==true end
function DT.Player.RemoveStatus(source,key,v) return call('removeStatus',source,key,v)==true end
function DT.Player.HasPermission(source,p) local v=call('hasPermission',source,p); if v~=nil and v~='unsupported_backend' then return v==true end; return IsPlayerAceAllowed(source,p) end
function DT.Player.GetCoords(source) local v=call('getCoords',source); if v then return v end; local ped=GetPlayerPed(source); return ped and ped~=0 and GetEntityCoords(ped) or nil end
function DT.Player.Save(source) return call('save',source)==true end
function DT.Player.GetData(source) return call('getData',source) or {} end
DT.Callback.Register('DTlib:internal:getPlayerData',function(source) return DT.Player.GetData(source) end)
