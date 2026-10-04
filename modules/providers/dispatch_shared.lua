local P=DT.Providers
local function normalized(data)
    assert(type(data)=='table','invalid_alert')
    local result=DTUtils.copy(data)
    result.coords=result.coords or (not P.Server and GetEntityCoords(PlayerPedId()))
    assert(result.coords,'alert_coords_required')
    result.message=result.message or result.title or 'Dispatch alert'
    result.code=result.code or '10-80';result.priority=result.priority or 2
    result.jobs=result.jobs or result.job or {'police'};if type(result.jobs)=='string' then result.jobs={result.jobs} end
    result.blipData=result.blipData or result.blip or {};result.time=tonumber(result.time) or 10000
    return result
end
local function blip(data)
    local b=data.blipData;return {sprite=b.sprite or 161,color=b.color or 1,scale=b.scale or 1,radius=b.radius or 0,length=math.max(1,data.time/60000)}
end
local function send(resource,data,src)
    local d=normalized(data);local b=blip(d)
    if resource=='native' then
        if not P.Server then return DT.Callback.Await('DTlib:provider:dispatch',resource,d) end
        local sent={}
        for _,name in ipairs(d.jobs) do for _,target in ipairs(DT.Ecosystem.Framework.GetPlayersByJob(name)) do if not sent[target] then sent[target]=true;TriggerClientEvent('DTlib:provider:dispatchNotice',target,d) end end end
        return true
    end
    if resource=='emergencydispatch' then return P.Event('emergencydispatch:emergencycall:new',d.jobs[1],d.message,d.coords,true) end
    if P.Server then
        if resource=='lb-tablet' then return P.Export(resource,'AddDispatch',{priority=({[1]='high',[2]='medium',[3]='low'})[d.priority] or 'medium',code=d.code,title=d.message,description=d.message,location={label=d.street or 'Reported location',coords=d.coords},time=d.time/1000,job=d.jobs[1]}) end
        if resource=='fd_dispatch' then return P.Export(resource,'addAlert',{title=d.message,description=d.message,groups=d.jobs,coords=d.coords,code=d.code,priority=d.priority,blip=b}) end
        if resource=='redutzu-mdt' then return P.Event('redutzu-mdt:server:addDispatchToMDT',{code=d.code,title=d.message,street=d.street,duration=d.time,coords=d.coords}) end
        if resource=='piotreq_gpt' then return P.Export(resource,'SendAlert',assert(src,'alert_source_required'),{title=d.message,code=d.code,icon=d.icon or 'fa-solid fa-bell',info={{data=d.message,icon='fa-solid fa-circle-info'}},blip={name=d.message,scale=b.scale,sprite=b.sprite,color=b.color,priority=d.priority},type='normal',time=d.time/60000}) end
        return nil,'client_only_method:SendAlert'
    end
    if resource=='lb-tablet' or resource=='redutzu-mdt' or resource=='piotreq_gpt' then return DT.Callback.Await('DTlib:provider:dispatch',resource,d) end
    if resource=='ps-dispatch' then return P.Export(resource,'CustomAlert',{message=d.message,code=d.code,icon=d.icon,priority=d.priority,coords=d.coords,vehicle=d.vehicle,plate=d.plate,alertTime=d.time/1000,radius=b.radius,sprite=b.sprite,color=b.color,scale=b.scale,length=b.length,jobs=d.jobs,flash=d.blipData.flash}) end
    if resource=='fd_dispatch' then return P.Export(resource,'CustomAlert',{title=d.message,description=d.message,coords=d.coords,groups=d.jobs,code=d.code,priority=d.priority,blip=b}) end
    if resource=='tk_dispatch' then return P.Export(resource,'addCall',{title=d.message,code=d.code,priority='Priority '..d.priority,coords=d.coords,showLocation=true,playSound=true,blip=b,jobs=d.jobs}) end
    if resource=='wasabi_mdt' then return P.Export(resource,'CreateDispatch',{type=d.code,title=d.code,description=d.message,location={d.coords.x,d.coords.y,d.coords.z},coords={d.coords.x,d.coords.y,d.coords.z}}) end
    if resource=='bub-mdt' then return P.Export(resource,'CustomAlert',{code=d.code,offense=d.message,coords=d.coords,info={label=d.code,icon=d.icon or 'fas fa-bell'},blip=b.sprite,isEmergency=d.priority==1,blipCoords=d.coords}) end
    if resource=='kartik-mdt' then local jobs={};for _,name in ipairs(d.jobs) do jobs[name]=true end;return P.Export(resource,'CustomAlert',{title=d.message,description=d.message,code=d.code,type='Alert',coords=d.coords,blip=b,jobs=jobs}) end
    if resource=='cd_dispatch' then local info=P.Export(resource,'GetPlayerInfo') or {};b.colour=b.color;b.time=d.time/60000;return P.Event('cd_dispatch:AddNotification',{job_table=d.jobs,coords=d.coords,title=d.code,message=d.message,flash=d.blipData.flash or 0,unique_id=info.unique_id or P.Id('alert'),sound=1,blip=b}) end
    if resource=='origen_police' then return P.Event('SendAlert:police',{coords=d.coords,title=d.code,message=d.message,job=d.jobs,metadata={}}) end
    if resource=='linden_outlawalert' then return P.Event('wf-alerts:svNotify',{dispatchData={displayCode=d.code,description=d.message,isImportant=d.priority==1,recipientList=d.jobs},caller=d.caller or 'Anonymous',coords=d.coords}) end
    if resource=='qs-dispatch' then b.colour=b.color;return P.Event('qs-dispatch:server:CreateDispatchCall',{job=d.jobs,callLocation=d.coords,callCode={code=d.code,snippet=d.message},message=d.message,flashes=d.blipData.flash or false,blip=b}) end
    return nil,'unsupported_method:SendAlert'
end
for _,definition in ipairs(DTEcosystemCatalog.dispatch.providers) do
    P.Register('dispatch',definition.resource,function(resource)
        if P.Server and not ({native=true,emergencydispatch=true,['lb-tablet']=true,fd_dispatch=true,['redutzu-mdt']=true,piotreq_gpt=true})[resource] then return {} end
        return {SendAlert=function(data,second)
            if type(data)=='number' then return send(resource,second,data) end
            return send(resource,data,data.source)
        end}
    end)
end
if P.Server then
    local cooldown={}
    DT.Callback.Register('DTlib:provider:dispatch',function(src,resource,data)
        if type(data)~='table' or type(data.message)~='string' or #data.message>1000 then return false,'invalid_alert' end
        if cooldown[src] and GetGameTimer()-cooldown[src]<3000 then return false,'rate_limited' end
        cooldown[src]=GetGameTimer();data=DTUtils.copy(data);data.coords=GetEntityCoords(GetPlayerPed(src))
        local api=DT.Ecosystem.Get('dispatch',resource);if not api or not api.SendAlert then return false,'unsupported_method' end
        return api.SendAlert(src,data)
    end)
    AddEventHandler('playerDropped',function() cooldown[source]=nil end)
else
    RegisterNetEvent('DTlib:provider:dispatchNotice',function(data)
        if source~=65535 then return end
        DT.Notify({title=data.code,message=data.message,duration=data.time})
        local b=blip(data);local mark=AddBlipForCoord(data.coords.x,data.coords.y,data.coords.z)
        SetBlipSprite(mark,b.sprite);SetBlipColour(mark,b.color);SetBlipScale(mark,b.scale)
        SetTimeout(math.max(1000,math.min(data.time,300000)),function() RemoveBlip(mark) end)
    end)
end
