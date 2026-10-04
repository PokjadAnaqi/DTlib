local A={resource='qb-target',publicName='qb-target'}
local function wrap(v) return DTUtils.wrapCallable(v) end
local function options(list)
    local out={}
    for i=1,#(list or {}) do local o=list[i]; if type(o)=='table' then local event=o.event; local typ='client'; if o.serverEvent then event=o.serverEvent; typ='server' elseif o.command then event=o.command; typ='command' end; out[#out+1]={num=o.num or i,label=o.label,icon=o.icon,canInteract=wrap(o.canInteract),action=wrap(o.onSelect or o.action),event=event,type=typ,job=o.job or o.groups,gang=o.gang,item=o.item or o.items} end end
    return out
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:addGlobalKind(kind,o)
    local payload={options=options(o),distance=2.0}
    if kind=='Object' then exports['qb-target']:AddGlobalObject(payload)
    elseif kind=='Ped' then exports['qb-target']:AddGlobalPed(payload)
    elseif kind=='Player' then exports['qb-target']:AddGlobalPlayer(payload)
    elseif kind=='Vehicle' then exports['qb-target']:AddGlobalVehicle(payload)
    else return false end
    return true
end
function A:removeGlobalKind(kind,n)
    if kind=='Object' then exports['qb-target']:RemoveGlobalObject(n)
    elseif kind=='Ped' then exports['qb-target']:RemoveGlobalPed(n)
    elseif kind=='Player' then exports['qb-target']:RemoveGlobalPlayer(n)
    elseif kind=='Vehicle' then exports['qb-target']:RemoveGlobalVehicle(n)
    else return false end
    return true
end
function A:addEntity(e,o,d) exports['qb-target']:AddTargetEntity(e,{options=options(o),distance=d or 2.0}); return true end
function A:removeEntity(e,n) exports['qb-target']:RemoveTargetEntity(e,n); return true end
function A:addModel(m,o,d) exports['qb-target']:AddTargetModel(m,{options=options(o),distance=d or 2.0}); return true end
function A:removeModel(m,n) exports['qb-target']:RemoveTargetModel(m,n); return true end
function A:addSphereZone(d)
    local name=d.name or ('dtlib_sphere_%s'):format(GetGameTimer()); exports['qb-target']:AddCircleZone(name,d.coords,d.radius or 1.5,{name=name,debugPoly=d.debug or false,useZ=d.useZ~=false},{options=options(d.options),distance=d.distance or 2.0}); return name
end
function A:addBoxZone(d)
    local name=d.name or ('dtlib_box_%s'):format(GetGameTimer()); local s=d.size or vector3(1.0,1.0,1.0); exports['qb-target']:AddBoxZone(name,d.coords,s.x,s.y,{name=name,heading=d.rotation or d.heading or 0.0,debugPoly=d.debug or false,minZ=d.minZ or (d.coords.z-s.z*0.5),maxZ=d.maxZ or (d.coords.z+s.z*0.5)},{options=options(d.options),distance=d.distance or 2.0}); return name
end
function A:addPolyZone(d)
    local name=d.name or ('dtlib_poly_%s'):format(GetGameTimer()); local pts={}; local minZ,maxZ; for i=1,#(d.points or {}) do pts[i]=vector2(d.points[i].x,d.points[i].y); minZ=math.min(minZ or d.points[i].z,d.points[i].z); maxZ=math.max(maxZ or d.points[i].z,d.points[i].z) end; local t=d.thickness or 4.0; exports['qb-target']:AddPolyZone(name,pts,{name=name,debugPoly=d.debug or false,minZ=d.minZ or ((minZ or 0)-t*0.5),maxZ=d.maxZ or ((maxZ or 0)+t*0.5)},{options=options(d.options),distance=d.distance or 2.0}); return name
end
function A:removeZone(id) exports['qb-target']:RemoveZone(id); return true end
DT.Modules.Register('target','qb-target',A)
