local A={resource='DT_interact',publicName='DT_interact'}
local function owner() return GetInvokingResource() or GetCurrentResourceName() end
local function options(value)
    local out={};if value and value.label then value={value} end
    for _,raw in ipairs(value or {}) do
        local o={};for k,v in pairs(raw) do o[k]=v end
        o.onSelect=DTUtils.wrapCallable(raw.onSelect or raw.action)
        o.canInteract=DTUtils.wrapCallable(raw.canInteract);out[#out+1]=o
    end;return out
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:disable(state) return exports.DT_interact:disableTargeting(state==true) end
function A:isActive() return exports.DT_interact:isActive() end
function A:getOptions(...) return exports.DT_interact:getTargetOptions(...) end
function A:addGlobal(o) return exports.DT_interact:addGlobalOption(options(o),owner()) end
function A:removeGlobal(n) return exports.DT_interact:removeGlobalOption(n,owner()) end
function A:addGlobalKind(kind,o) local h=exports.DT_interact;return h['addGlobal'..kind](h,options(o),owner()) end
function A:removeGlobalKind(kind,n) local h=exports.DT_interact;return h['removeGlobal'..kind](h,n,owner()) end
function A:addEntity(e,o,d) local list=options(o);for _,v in ipairs(list) do v.distance=v.distance or d end;return exports.DT_interact:addLocalEntity(e,list,owner()) end
function A:removeEntity(e,n) return exports.DT_interact:removeLocalEntity(e,n,owner()) end
function A:addNetworkEntity(e,o) return exports.DT_interact:addEntity(e,options(o),owner()) end
function A:removeNetworkEntity(e,n) return exports.DT_interact:removeEntity(e,n,owner()) end
function A:addModel(m,o,d) local list=options(o);for _,v in ipairs(list) do v.distance=v.distance or d end;return exports.DT_interact:addModel(m,list,owner()) end
function A:removeModel(m,n) return exports.DT_interact:removeModel(m,n,owner()) end
for public in pairs({Sphere=true,Box=true,Poly=true}) do local name=public
    A['add'..name..'Zone']=function(_,d) local copy={};for k,v in pairs(d) do copy[k]=v end;copy.options=options(d.options);local h=exports.DT_interact;return h['add'..name..'Zone'](h,copy,owner()) end
end
function A:zoneExists(id) return exports.DT_interact:zoneExists(id) end
function A:removeZone(id) return exports.DT_interact:removeZone(id,true,owner()) end
DT.Modules.Register('target','DT_interact',A)
