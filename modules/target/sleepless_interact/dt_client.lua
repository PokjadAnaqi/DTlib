local A={resource='sleepless_interact',publicName='sleepless_interact'}
local function call(method,...)
    local api,err=DT.Ecosystem.Get('target','sleepless_interact')
    if not api then return nil,err end
    if not DTUtils.isCallable(api[method]) then return nil,'unsupported_backend' end
    return api[method](...)
end
function A:available() return DTConfig.Ecosystem.enabled~=false and DTUtils.isStarted(self.resource) end
function A:disable(state) call('DisableTargeting',state==true);return true end
function A:addGlobalKind(kind,options) return call('AddGlobal'..kind,options) end
function A:removeGlobalKind(kind,names) return call('RemoveGlobal'..kind,names) end
function A:addEntity(entity,options) call('AddLocalEntity',entity,options);return true end
function A:removeEntity(entity,names) call('RemoveLocalEntity',entity,names);return true end
function A:addNetworkEntity(entity,options) call('AddNetworkedEntity',entity,options);return true end
function A:removeNetworkEntity(entity,names) call('RemoveNetworkedEntity',entity,names);return true end
function A:addModel(models,options) call('AddModel',models,options);return true end
function A:removeModel(models) call('RemoveModel',models);return true end
function A:addSphereZone(data) return call('AddSphereZone',data.name,data.coords,data.radius or 1.5,data.options,data.debug) end
function A:addBoxZone(data) return call('AddBoxZone',data.name,data.coords,data.size,data.rotation or data.heading,data.options) end
function A:removeZone(name) call('RemoveZone',name);return true end
DT.Modules.Register('target','sleepless_interact',A)
