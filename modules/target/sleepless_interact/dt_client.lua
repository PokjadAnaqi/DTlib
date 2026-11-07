local adapter = { resource = 'sleepless_interact', publicName = 'sleepless_interact' }
local function call(method, ...)
    local api, errorMessage = DT.Ecosystem.Get('target', 'sleepless_interact')
    if not api then
        return nil, errorMessage
    end
    if not DTUtils.isCallable(api[method]) then
        return nil, 'unsupported_backend'
    end
    return api[method](...)
end
function adapter:available()
    return DTConfig.Ecosystem.enabled ~= false and DTUtils.isStarted(self.resource)
end
function adapter:disable(state)
    call('DisableTargeting', state == true)
    return true
end
function adapter:addGlobalKind(kind, options)
    return call('AddGlobal' .. kind, options)
end
function adapter:removeGlobalKind(kind, names)
    return call('RemoveGlobal' .. kind, names)
end
function adapter:addEntity(entity, options)
    call('AddLocalEntity', entity, options)
    return true
end
function adapter:removeEntity(entity, names)
    call('RemoveLocalEntity', entity, names)
    return true
end
function adapter:addNetworkEntity(entity, options)
    call('AddNetworkedEntity', entity, options)
    return true
end
function adapter:removeNetworkEntity(entity, names)
    call('RemoveNetworkedEntity', entity, names)
    return true
end
function adapter:addModel(models, options)
    call('AddModel', models, options)
    return true
end
function adapter:removeModel(models)
    call('RemoveModel', models)
    return true
end
function adapter:addSphereZone(data)
    return call('AddSphereZone', data.name, data.coords, data.radius or 1.5, data.options, data.debug)
end
function adapter:addBoxZone(data)
    return call('AddBoxZone', data.name, data.coords, data.size, data.rotation or data.heading, data.options)
end
function adapter:removeZone(name)
    call('RemoveZone', name)
    return true
end
DT.Modules.Register('target', 'sleepless_interact', adapter)
