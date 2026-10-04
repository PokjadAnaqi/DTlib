local P=DT.Providers
local function base(category,resource,method,...)
    local adapter=DT.Modules.Get(category,resource)
    if not adapter or not adapter[method] then return nil,'unsupported_method:'..method end
    return adapter[method](adapter,...)
end
local own={native=true,lation_ui=true,ox_lib=true,okokNotify=true,okokTextUI=true}
for _,definition in ipairs(DTEcosystemCatalog.notify.providers) do
    P.Register('notify',definition.resource,function(resource)
        local api={}
        function api.SendNotification(title,message,kind,duration,properties)
            kind=kind or 'inform';duration=duration or 5000
            if own[resource] then
                local data=DTUtils.copy(properties or {});data.title=title;data.message=message;data.type=kind;data.duration=duration
                return base('notify',resource,'send',data)
            end
            if resource=='brutal_notify' then return P.Export(resource,'SendAlert',title,message,duration,kind,false) end
            if resource=='FL-Notify' then return P.Export(resource,'Notify',title or 'Notification','',message,duration,tonumber(kind) or 1,0) end
            if resource=='msk_core' then return P.Export(resource,'Notify',title,message,kind,duration) end
            if resource=='mythic_notify' then return P.Export(resource,'SendAlert',kind,message,duration) end
            if resource=='pNotify' then return P.Export(resource,'SendNotification',{title=title,text=message,type=kind,timeout=duration,layout='centerRight'}) end
            if resource=='r_notify' then return P.Export(resource,'notify',{title=title,content=message,type=kind,duration=duration,position='top-right',sound=false}) end
            if resource=='solaire_notify' then return P.Export(resource,'Notify',{title=title,message=message,type=kind,duration=duration}) end
            if resource=='t-notify' then return P.Export(resource,'Alert',{title=title,message=message,style=kind,duration=duration}) end
            if resource=='wasabi_notify' then return P.Export(resource,'notify',title,message,duration,kind) end
            if resource=='ZSX_UIV2' then return P.Export(resource,'Notification',title,message,properties and properties.icon or 'fa-solid fa-info-circle',duration) end
        end
        function api.SendNotify(message,kind,duration) return api.SendNotification(nil,message,kind,duration) end
        return api
    end)
end
for _,definition in ipairs(DTEcosystemCatalog.helptext.providers) do
    P.Register('helptext',definition.resource,function(resource)
        return {
            ShowHelpText=function(message,position)
                if own[resource] then return base('helptext',resource,'show',{description=message,text=message,position=position}) end
                if resource=='cd_drawtextui' then TriggerEvent('cd_drawtextui:ShowUI','show',message);return true end
                if resource=='jg-textui' then return P.Export(resource,'DrawText',message) end
                if resource=='lab-HintUI' then return P.Export(resource,'Show',message,'DTlib') end
                if resource=='ZSX_UIV2' then return P.Export(resource,'TextUI_Persistent',nil,message,nil,nil,nil) end
            end,
            HideHelpText=function()
                if own[resource] then return base('helptext',resource,'hide') end
                if resource=='cd_drawtextui' then TriggerEvent('cd_drawtextui:HideUI');return true end
                if resource=='jg-textui' then return P.Export(resource,'HideText') end
                if resource=='lab-HintUI' then return P.Export(resource,'Hide') end
                if resource=='ZSX_UIV2' then return P.Export(resource,'TextUI_RemovePersistent',false) end
            end
        }
    end)
end
for _,definition in ipairs(DTEcosystemCatalog.progressbar.providers) do
    P.Register('progressbar',definition.resource,function(resource)
        return {Open=function(options,style)
            if own[resource] then return base('progressbar',resource,'run',options) end
            if resource=='keep-progressbar' then return P.Export(resource,'ox_lib_progressBar',options) end
            if resource=='wasabi_uikit' then return P.Export(resource,'ProgressBar',options,style or 'bar') end
            if resource=='progressbar' then return P.WaitCallback(function(done) P.Export(resource,'Progress',options,function(cancelled) done(not cancelled) end) end) end
            if resource=='msk_core' then
                P.Export(resource,'Progressbar',options)
                while P.Export(resource,'ProgressActive') do Wait(50) end
                return true
            end
            if resource=='ZSX_UIV2' then
                local disable=options.disable or {};local props=options.prop or {};if props.model then props={props} end
                return P.WaitCallback(function(done)
                    P.Export(resource,'ProgressBar','fas fa-circle-notch',options.label,options.duration or 5000,function() done(true) end,function() done(false) end,options.canCancel~=false,
                        {disable_mouse=disable.mouse,disable_walk=disable.move,disable_driving=disable.car,disable_combat=disable.combat},options.anim,props[1],props[2])
                end)
            end
            return nil,'unsupported_method:Open'
        end}
    end)
end
for _,definition in ipairs(DTEcosystemCatalog.input.providers) do
    P.Register('input',definition.resource,function(resource)
        return {Open=function(title,fields,isQB,submitText)
            if resource=='qb-input' then
                local values=P.Export(resource,'ShowInput',{header=title,submitText=submitText or 'Submit',inputs=fields})
                if not values then return nil end
                local result={};for i,field in ipairs(fields) do result[i]=values[field.name or tostring(i)] end;return result
            end
            -- DT's native input owns its NUI waiter; explicit override avoids recursive selection.
            if resource=='native' then return DT.Input.Await({title=title,fields=fields,provider='native'}) end
            return base('input',resource,'await',{title=title,submitText=submitText},fields)
        end}
    end)
end
for _,definition in ipairs(DTEcosystemCatalog.menu.providers) do
    P.Register('menu',definition.resource,function(resource)
        return {Open=function(data,isQB)
            if resource=='qb-menu' then
                if isQB then return P.Export(resource,'openMenu',data) end
                local rows={{header=data.title or 'MENU',isMenuHeader=true}}
                for _,option in ipairs(data.options or {}) do
                    local token=P.Id('menu')
                    DT.ProviderMenuActions[token]=option.onSelect
                    rows[#rows+1]={header=option.title,txt=option.description,icon=option.icon,disabled=option.disabled,params={event='DTlib:provider:menuSelect',args=token}}
                end
                return P.Export(resource,'openMenu',rows)
            end
            if resource=='wasabi_uikit' then P.Export(resource,'RegisterContextMenu',data);return P.Export(resource,'OpenContextMenu',data.id) end
            if resource=='native' then local options=DTUtils.copy(data);options.provider='native';return DT.Menu.Open(options) end
            local options=data.options or {};return base('menu',resource,'open',data.id or P.Id('menu'),data,options,function(index)
                local row=options[index];if row and row.onSelect then row.onSelect(row.args) end
            end,data.onExit)
        end}
    end)
end
DT.ProviderMenuActions={}
AddEventHandler('DTlib:provider:menuSelect',function(token)
    local action=DT.ProviderMenuActions[token];DT.ProviderMenuActions={}
    if type(action)=='function' then action() end
end)
