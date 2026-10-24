local P=DT.Providers
for _,definition in ipairs(DTEcosystemCatalog.target.providers) do
    P.Register('target',definition.resource,function(resource)
        local adapter=DT.Modules.Get('target',DTConfig.Interaction and DTConfig.Interaction.mode=='interact' and 'dtlib_interact' or resource=='native' and 'none' or resource);assert(adapter,'target_adapter_missing')
        local api={}
        local function call(method,...)
            if not adapter[method] then return nil,'unsupported_method:'..method end
            return adapter[method](adapter,...)
        end
        local direct={DisableTargeting='disable',AddLocalEntity='addEntity',RemoveLocalEntity='removeEntity',AddNetworkedEntity='addNetworkEntity',RemoveNetworkedEntity='removeNetworkEntity',AddModel='addModel',RemoveModel='removeModel',RemoveZone='removeZone'}
        for public,private in pairs(direct) do local name=private;api[public]=function(...) return call(name,...) end end
        for _,kind in ipairs({'Ped','Player','Vehicle'}) do local name=kind
            api['AddGlobal'..kind]=function(options) return call('addGlobalKind',name,options) end
            api['RemoveGlobal'..kind]=function(options) return call('removeGlobalKind',name,options) end
        end
        function api.AddBoxZone(name,coords,size,heading,options,debug) return call('addBoxZone',{name=name,coords=coords,size=size,rotation=heading,options=options,debug=debug}) end
        function api.AddSphereZone(name,coords,radius,options,debug) return call('addSphereZone',{name=name,coords=coords,radius=radius,options=options,debug=debug}) end
        api.FixOptions=DTUtils.copy
        function api.CreateCanInteract(requirements)
            return function(entity,distance,coords,name,bone)
                if requirements.distance and distance>requirements.distance then return false end
                if requirements.groups and not DT.Player.HasGroup(requirements.groups) then return false end
                if requirements.canInteract then return requirements.canInteract(entity,distance,coords,name,bone)==true end
                return true
            end
        end
        api.GetCanInteract=api.CreateCanInteract
        api.CanInteract=function(requirements,...) return api.CreateCanInteract(requirements)(...) end
        return api
    end)
end
for _,definition in ipairs(DTEcosystemCatalog.weather.providers) do
    P.Register('weather',definition.resource,function(resource)
        return {ToggleSync=function(enabled)
            if resource=='Renewed-Weathersync' then LocalPlayer.state:set('syncWeather',enabled==true,false)
            elseif resource=='qb-weathersync' then TriggerEvent(enabled and 'qb-weathersync:client:EnableSync' or 'qb-weathersync:client:DisableSync')
            elseif resource=='cd_easytime' then TriggerEvent('cd_easytime:PauseSync',not enabled)
            else return nil,'unsupported_method:ToggleSync' end
            return true
        end}
    end)
end
-- Zone ownership is DTlib's; geometry uses the existing DT.Zone implementation.
for _,definition in ipairs(DTEcosystemCatalog.zones.providers) do
    P.Register('zones',definition.resource,function(resource)
        local entries={};local api={}
        function api.Create(kind,data)
            local methods={box=DT.Zone.Box,sphere=DT.Zone.Sphere,poly=DT.Zone.Poly}
            assert(methods[kind],'unknown_zone_type')
            local entry=DTUtils.copy(data);entry.id=P.Id('zone');entry.invoking=GetInvokingResource() or GetCurrentResourceName()
            local options=DTUtils.copy(data)
            options.rotation=options.rotation or options.heading
            options.onEnter=function() if data.onEnter or data.OnEnter then (data.onEnter or data.OnEnter)(entry) end end
            options.onExit=function() if data.onExit or data.OnExit then (data.onExit or data.OnExit)(entry) end end
            entry.zone=methods[kind](options);entries[entry.id]=entry;return entry.id
        end
        function api.Get(id) return entries[id] end
        function api.Destroy(id) local entry=entries[id];if not entry then return false end;DT.Zone.Remove(entry.zone);entries[id]=nil;return true end
        function api.DestroyByResource(owner) local ids={};for id,entry in pairs(entries) do if entry.invoking==owner then ids[#ids+1]=id end end;for _,id in ipairs(ids) do api.Destroy(id) end;return true end
        AddEventHandler('onClientResourceStop',api.DestroyByResource)
        return api
    end)
end
P.Register('dialogue','native',function()
    local active;local api={}
    function api.Close(name)
        if not active or name and name~=active.name then return false end
        local entry=active;active=nil;DT.Menu.Close();entry.waiter:resolve(nil);return true
    end
    function api.Open(name,text,character,options,onSelected)
        api.Close();local entry={name=name,waiter=promise.new()};active=entry
        local items={}
        for i,option in ipairs(options) do
            local value=option.id or i
            items[i]={title=option.label or option.title or option.text,description=option.description,disabled=option.disabled,onSelect=function()
                if active~=entry then return end;active=nil;entry.waiter:resolve(value);if onSelected then onSelected(value) end
            end}
        end
        DT.Menu.Open({id=name,title=name,subtitle=text,items=items,onExit=function() api.Close(name) end})
        return Citizen.Await(entry.waiter)
    end
    return api
end)
