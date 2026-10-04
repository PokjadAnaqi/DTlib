local A={resource='ox_target',publicName='ox_target'}
local function wrap(v) return DTUtils.wrapCallable(v) end
local function options(list)
    local out={}
    for i=1,#(list or {}) do local o=list[i]; if type(o)=='table' then out[#out+1]={name=o.name,label=o.label,icon=o.icon,iconColor=o.iconColor,distance=o.distance,bones=o.bones,offset=o.offset,offsetAbsolute=o.offsetAbsolute,offsetSize=o.offsetSize,groups=o.groups or o.job or o.gang,items=o.items or o.item,anyItem=o.anyItem,canInteract=wrap(o.canInteract),menuName=o.menuName,openMenu=o.openMenu,onSelect=wrap(o.onSelect or o.action),export=o.export,event=o.event,serverEvent=o.serverEvent,command=o.command} end end
    return out
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:disable(state) exports.ox_target:disableTargeting(state==true); return true end
function A:isActive() local ok,v=pcall(function() return exports.ox_target:isActive() end); return ok and v==true end
function A:getOptions(...) local args={...}; local ok,v=pcall(function() return exports.ox_target:getTargetOptions(table.unpack(args)) end); return ok and v or nil end
function A:addGlobal(o) exports.ox_target:addGlobalOption(options(o)); return true end
function A:removeGlobal(n) exports.ox_target:removeGlobalOption(n); return true end
function A:addGlobalKind(kind,o)
    o=options(o)
    if kind=='Object' then exports.ox_target:addGlobalObject(o)
    elseif kind=='Ped' then exports.ox_target:addGlobalPed(o)
    elseif kind=='Player' then exports.ox_target:addGlobalPlayer(o)
    elseif kind=='Vehicle' then exports.ox_target:addGlobalVehicle(o)
    else return false end
    return true
end
function A:removeGlobalKind(kind,n)
    if kind=='Object' then exports.ox_target:removeGlobalObject(n)
    elseif kind=='Ped' then exports.ox_target:removeGlobalPed(n)
    elseif kind=='Player' then exports.ox_target:removeGlobalPlayer(n)
    elseif kind=='Vehicle' then exports.ox_target:removeGlobalVehicle(n)
    else return false end
    return true
end
function A:addEntity(e,o) exports.ox_target:addLocalEntity(e,options(o)); return true end
function A:removeEntity(e,n) exports.ox_target:removeLocalEntity(e,n); return true end
function A:addNetworkEntity(e,o) exports.ox_target:addEntity(e,options(o)); return true end
function A:removeNetworkEntity(e,n) exports.ox_target:removeEntity(e,n); return true end
function A:addModel(m,o) exports.ox_target:addModel(m,options(o)); return true end
function A:removeModel(m,n) exports.ox_target:removeModel(m,n); return true end
function A:addSphereZone(d) return exports.ox_target:addSphereZone({coords=d.coords,name=d.name,radius=d.radius or 1.5,debug=d.debug or false,drawSprite=d.drawSprite,options=options(d.options)}) end
function A:addBoxZone(d) return exports.ox_target:addBoxZone({coords=d.coords,name=d.name,size=d.size or vector3(1.0,1.0,1.0),rotation=d.rotation or d.heading or 0.0,debug=d.debug or false,drawSprite=d.drawSprite,options=options(d.options)}) end
function A:addPolyZone(d) return exports.ox_target:addPolyZone({points=d.points,name=d.name,thickness=d.thickness or 4.0,debug=d.debug or false,drawSprite=d.drawSprite,options=options(d.options)}) end
function A:zoneExists(id) local ok,v=pcall(function() return exports.ox_target:zoneExists(id) end); return ok and v==true end
function A:removeZone(id) exports.ox_target:removeZone(id); return true end
DT.Modules.Register('target','ox_target',A)
