local aliases={ox='ox_target',qb='qb-target'}
local managed={}
local function A()
    if DTConfig.Interaction and DTConfig.Interaction.mode=='interact' then return DT.Modules.Get('target','dtlib_interact') end
    return DT.Modules.Resolve('target',DTConfig.Adapters.target,{'ox_target','qb-target','sleepless_interact'},aliases,'none')
end
local function call(m,...) local a=A(); if not a or type(a[m])~='function' then return nil,'unsupported_backend' end; return a[m](a,...) end
function DT.Target.Name() local a=A(); return a and a.publicName or 'none' end
function DT.Target.Available() local a=A(); return a and a.resource~='none' end
function DT.Target.Disable(state) return call('disable',state) end
DT.Target.DisableTargeting=DT.Target.Disable
function DT.Target.IsActive() return call('isActive')==true end
function DT.Target.GetOptions(...) return call('getOptions',...) end
function DT.Target.AddGlobal(o) return call('addGlobal',o) end
function DT.Target.RemoveGlobal(n) return call('removeGlobal',n) end
for _,kind in ipairs({'Object','Ped','Player','Vehicle'}) do
    DT.Target['AddGlobal'..kind]=function(o) return call('addGlobalKind',kind,o) end
    DT.Target['RemoveGlobal'..kind]=function(n) return call('removeGlobalKind',kind,n) end
end
function DT.Target.AddEntity(e,o,d) return call('addEntity',e,o,d) end
DT.Target.AddLocalEntity=DT.Target.AddEntity
function DT.Target.RemoveEntity(e,n) return call('removeEntity',e,n) end
DT.Target.RemoveLocalEntity=DT.Target.RemoveEntity
function DT.Target.AddNetworkEntity(e,o) return call('addNetworkEntity',e,o) end
function DT.Target.RemoveNetworkEntity(e,n) return call('removeNetworkEntity',e,n) end
function DT.Target.AddModel(m,o,d) return call('addModel',m,o,d) end
function DT.Target.RemoveModel(m,n) return call('removeModel',m,n) end
local function addZone(method,d) local id=call(method,d or {}); if id and id~=false then managed[id]=true; if d and d.name then managed[d.name]=true end end; return id end
function DT.Target.AddSphereZone(d) return addZone('addSphereZone',d) end
function DT.Target.AddBoxZone(d) return addZone('addBoxZone',d) end
function DT.Target.AddPolyZone(d) return addZone('addPolyZone',d) end
function DT.Target.ZoneExists(id) local v=call('zoneExists',id); return v~=nil and v or managed[id]==true end
function DT.Target.RemoveZone(id) local v=call('removeZone',id); if v then managed[id]=nil end; return v end
