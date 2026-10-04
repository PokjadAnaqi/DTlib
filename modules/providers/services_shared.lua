local P=DT.Providers
local E=DT.Ecosystem
for _,definition in ipairs(DTEcosystemCatalog.phone.providers) do
    P.Register('phone',definition.resource,function(resource)
        local api={GetPhoneName=function() return resource end}
        if P.Server then
            function api.GetPlayerPhone(src)
                local method={['lb-phone']='GetEquippedPhoneNumber',okokPhone='getPhoneNumberFromSource',gksphone='GetPhoneBySource',yseries='GetPhoneNumberBySourceId'}
                if method[resource] then return P.Export(resource,method[resource],src) end
                if resource=='qs-smartphone' then return P.Export('qs-base','GetPlayerPhone',src) end
                local d=DT.Player.GetData(src);return (d.charinfo or d).phone
            end
            function api.SendEmail(src,sender,title,message)
                if resource=='lb-phone' then
                    local number=api.GetPlayerPhone(src);if not number then return false,'phone_not_found' end
                    local address=P.Export(resource,'GetEmailAddress',number);if not address then return false,'email_not_found' end
                    return P.Export(resource,'SendMail',{to=address,sender=sender,subject=title,message=message})
                end
                if resource=='okokPhone' then
                    local address=P.Export(resource,'getEmailAddressFromSource',src);if not address then return false,'email_not_found' end
                    return P.Export(resource,'sendEmail',{sender=sender,recipients={address},subject=title,body=message})
                end
                if resource=='gksphone' then return P.Export(resource,'SendNewMail',src,{sender=sender,subject=title,message=message,image='/html/static/img/icons/mail.png'}) end
                if resource=='qb-phone' then return P.Export(resource,'sendNewMailToOffline',DT.Player.GetIdentifier(src),{sender=sender,subject=title,message=message,button={}}) end
                if resource=='yseries' then return P.Export(resource,'SendMail',{title=title,sender=sender,senderDisplayName=sender,content=message},'phoneNumber',api.GetPlayerPhone(src)) end
                if resource=='qs-smartphone' then TriggerClientEvent('DTlib:provider:phoneMail',src,resource,sender,title,message);return true end
                return nil,'unsupported_method:SendEmail'
            end
        else
            function api.GetPlayerPhone() return DT.Callback.Await('DTlib:provider:phoneNumber',resource) end
            function api.SendEmail(sender,title,message) return DT.Callback.Await('DTlib:provider:phoneMail',resource,sender,title,message) end
        end
        return api
    end)
end
if P.Server then
    local mailTimes={}
    DT.Callback.Register('DTlib:provider:phoneNumber',function(src,resource)
        local api=E.Get('phone',resource);return api and api.GetPlayerPhone(src)
    end)
    DT.Callback.Register('DTlib:provider:phoneMail',function(src,resource,sender,title,message)
        if type(sender)~='string' or #sender>254 or type(title)~='string' or #title>200 or type(message)~='string' or #message>8000 then return false,'invalid_mail' end
        local now=GetGameTimer();if mailTimes[src] and now-mailTimes[src]<5000 then return false,'rate_limited' end;mailTimes[src]=now
        local api=E.Get('phone',resource);return api and api.SendEmail(src,sender,title,message)
    end)
    AddEventHandler('playerDropped',function() mailTimes[source]=nil end)
else
    RegisterNetEvent('DTlib:provider:phoneMail',function(resource,sender,title,message)
        if source~=65535 or resource~='qs-smartphone' then return end
        TriggerServerEvent('qs-smartphone:server:sendNewMail',{sender=sender,subject=title,message=message})
    end)
end
for _,definition in ipairs(DTEcosystemCatalog.doorlock.providers) do
    P.Register('doorlock',definition.resource,function(resource)
        local api={}
        if P.Server then
            local method={doors_creator='setDoorState',ox_doorlock='setDoorState',rcore_doorlock='changeDoorState'}
            if method[resource] then api.ToggleDoorLock=function(id,locked)
                return P.Export(resource,method[resource],tonumber(id) or id,resource=='rcore_doorlock' and (locked and 0 or 1) or (locked and 1 or 0))
            end end
            if resource=='qb-doorlock' then api.ToggleDoorLock=function(id,locked) TriggerClientEvent('qb-doorlock:client:setState',-1,0,id,locked==true,false,false,false);return true end end
        else
            local method={doors_creator='getClosestActiveDoor',ox_doorlock='getClosestDoor',['qb-doorlock']='GetClosestDoor'}
            if method[resource] then api.GetClosestDoor=function() local door=P.Export(resource,method[resource]);return type(door)=='table' and door.id or door end end
            if resource=='rcore_doorlock' then api.GetClosestDoor=function()
                local best,range=nil,math.huge;local pos=GetEntityCoords(PlayerPedId())
                for _,door in pairs(P.Export(resource,'getLoadedDoors') or {}) do local distance=#(pos-door.coords);if distance<range then best,range=door.id,distance end end;return best
            end end
        end
        return api
    end)
end
for _,definition in ipairs(DTEcosystemCatalog.bossmenu.providers) do
    P.Register('bossmenu',definition.resource,function(resource)
        return {OpenBossMenu=function(src,job,kind)
            if P.Server then
                local actual=DT.Player.GetJob(src)
                if not actual or actual.name~=job or not (actual.isboss or actual.boss) then return false,'not_job_boss' end
                TriggerClientEvent('DTlib:provider:bossOpen',src,resource,job,kind);return true
            end
            job,kind=src,job
            if resource=='qb-management' then TriggerEvent('qb-bossmenu:client:OpenMenu');return true end
            if resource=='esx_society' then TriggerEvent('esx_society:openBossMenu',job,function(menu) if menu and menu.close then menu.close() end end,{wash=false});return true end
            if resource=='qbx_management' then return P.Export(resource,'OpenBossMenu',kind or 'job') end
            if resource=='tk_bosstablet' then return P.Export(resource,'openBossMenu') end
            if resource=='zat-bossmenu' then return P.Export(resource,'OpenBossMenu',kind or 'job') end
            return nil,'unsupported_method:OpenBossMenu'
        end}
    end)
end
if not P.Server then RegisterNetEvent('DTlib:provider:bossOpen',function(resource,job,kind)
    if source~=65535 then return end;local api=E.Get('bossmenu',resource);if api then api.OpenBossMenu(job,kind) end
end) end
for _,definition in ipairs(DTEcosystemCatalog.housing.providers) do P.Register('housing',definition.resource,function()
    return {GetInterior=function(src) return P.Server and Player(src).state.dtlibInterior or LocalPlayer.state.dtlibInterior end}
end) end
if not P.Server then
    AddEventHandler('Housing:client:EnterHome',function(id) LocalPlayer.state:set('dtlibInterior',id,true) end)
    AddEventHandler('Housing:client:DeleteFurnitures',function() LocalPlayer.state:set('dtlibInterior',false,true) end)
end
