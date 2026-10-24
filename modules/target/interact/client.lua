-- DTlib E interaction engine. Only registrations routed through DT.Target are owned here.
local A={resource='native',publicName='dtlib_interact'}
local entries,sequence,disabled={},0,false
local active,selected,lastAction=nil,1,0
local dui,texture,lastPayload,duiReady=nil,nil,nil,false
local function config() return DTConfig.Interaction or {} end
local function owner() return GetInvokingResource() or GetCurrentResourceName() end
local function array(value) if type(value)=='table' then return value end;return {value} end
local function distance(a,b) local x,y,z=a.x-b.x,a.y-b.y,a.z-b.z;return math.sqrt(x*x+y*y+z*z) end
local function add(kind,ref,options,range)
    sequence=sequence+1;entries[sequence]={id=sequence,kind=kind,ref=ref,options=options or {},distance=range,owner=owner()};return sequence
end
local function matches(names,o) for _,n in pairs(array(names)) do if n==o.name or n==o.label then return true end end end
local function remove(kind,ref,names)
    for id,e in pairs(entries) do
        if e.kind==kind and (ref==nil or e.ref==ref) then
            if names==nil then entries[id]=nil else
                local keep={};for _,o in ipairs(e.options) do if not matches(names,o) then keep[#keep+1]=o end end
                e.options=keep;if #keep==0 then entries[id]=nil end
            end
        end
    end
    return true
end
function A:available() return true end
function A:disable(value) disabled=value==true;active=nil;return true end
function A:isActive() return active~=nil and not disabled end
function A:addEntity(entities,options,range) for _,entity in pairs(array(entities)) do add('entity',entity,options,range) end;return true end
function A:removeEntity(entities,names) for _,entity in pairs(array(entities)) do remove('entity',entity,names) end;return true end
function A:addNetworkEntity(ids,options,range) for _,id in pairs(array(ids)) do add('network',id,options,range) end;return true end
function A:removeNetworkEntity(ids,names) for _,id in pairs(array(ids)) do remove('network',id,names) end;return true end
function A:addModel(models,options,range) for _,model in pairs(array(models)) do add('model',type(model)=='string' and joaat(model) or model,options,range) end;return true end
function A:removeModel(models,names) for _,model in pairs(array(models)) do remove('model',type(model)=='string' and joaat(model) or model,names) end;return true end
function A:addGlobal(options) add('global','All',options);return true end
function A:removeGlobal(names) return remove('global','All',names) end
function A:addGlobalKind(kind,options) add('global',kind,options);return true end
function A:removeGlobalKind(kind,names) return remove('global',kind,names) end
function A:addSphereZone(data) return add('sphere',data,data.options,data.distance) end
function A:addBoxZone(data) return add('box',data,data.options,data.distance) end
function A:addPolyZone(data) return add('poly',data,data.options,data.distance) end
function A:zoneExists(value) for id,e in pairs(entries) do if e.kind=='sphere' or e.kind=='box' or e.kind=='poly' then if id==value or e.ref.name==value then return true end end end;return false end
function A:removeZone(value) for id,e in pairs(entries) do if (e.kind=='sphere' or e.kind=='box' or e.kind=='poly') and (id==value or e.ref.name==value) then entries[id]=nil end end;return true end
local function inside(e,p)
    local d=e.ref
    if e.kind=='sphere' then return distance(p,d.coords)<=(d.radius or 1.5),d.coords end
    if e.kind=='box' then
        local s=d.size or vector3(1,1,1);local angle=math.rad(-(d.rotation or d.heading or 0));local dx,dy=p.x-d.coords.x,p.y-d.coords.y
        local x,y=dx*math.cos(angle)-dy*math.sin(angle),dx*math.sin(angle)+dy*math.cos(angle)
        return math.abs(x)<=s.x/2 and math.abs(y)<=s.y/2 and p.z>=(d.minZ or d.coords.z-s.z/2) and p.z<=(d.maxZ or d.coords.z+s.z/2),d.coords
    end
    local points=d.points or {};if #points<3 then return false end
    local hit=false;local j=#points;local z=0
    for i=1,#points do local a,b=points[i],points[j];z=z+a.z
        if (a.y>p.y)~=(b.y>p.y) and p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x then hit=not hit end;j=i
    end
    z=z/#points;return hit and math.abs(p.z-z)<=(d.thickness or 4)/2,vector3(p.x,p.y,z)
end
local function itemGate(items,any)
    if type(items)=='string' then return DT.Inventory.HasItem(items,1) end
    local found=false
    for key,value in pairs(items or {}) do local name,count=key,value;if type(key)=='number' then name,count=value,1 end
        local yes=DT.Inventory.HasItem(name,tonumber(count) or 1);if any and yes then return true end;if not any and not yes then return false end;found=true
    end
    return not any or not found
end
function A:eligible(o,entity,dist,coords)
    if o.disabled or o.readOnly or dist>(o.distance or config().interactDistance or 2) then return false end
    -- Do not silently execute specialised target options without their semantics.
    if o.bones or o.offset or o.offsetAbsolute or o.menuName or o.openMenu then return false end
    if (o.groups or o.job) and not DT.Player.HasGroup(o.groups or o.job) then return false end
    if o.gang and not DT.Player.HasGroup(o.gang) then return false end
    if (o.items or o.item) and not itemGate(o.items or o.item,o.anyItem) then return false end
    if o.canInteract then local ok,result=DTUtils.safeCall(o.canInteract,entity,dist,coords,o.name,nil);if not ok or result~=true then return false end end
    return true
end
local function blocked()
    return disabled or IsPauseMenuActive() or IsNuiFocused() or IsEntityDead(PlayerPedId()) or (DT.ProgressActive and DT.ProgressActive()) or (DT.UI.IsSuspended and DT.UI.IsSuspended()) or LocalPlayer.state.dtlibUiSuspended==true
end
function A:collect(p,pool)
    local best
    local function consider(e,entity,coords,dist,zone)
        if not zone and dist>(e.distance or config().drawDistance or 8) then return end
        if not zone and config().requireLook~=false then
            local cam=GetGameplayCamCoord();local rot=GetGameplayCamRot(2);local pitch,yaw=math.rad(rot.x),math.rad(rot.z)
            local dx,dy,dz=coords.x-cam.x,coords.y-cam.y,coords.z-cam.z;local len=math.sqrt(dx*dx+dy*dy+dz*dz)
            if len>0 and (dx*(-math.sin(yaw)*math.cos(pitch))+dy*(math.cos(yaw)*math.cos(pitch))+dz*math.sin(pitch))/len<0.95 then return end
            if entity~=0 and not HasEntityClearLosToEntity(PlayerPedId(),entity,17) then return end
        end
        local options={};for _,o in ipairs(e.options) do
            local effective=zone and 0 or dist
            if self:eligible(o,entity,effective,coords) then options[#options+1]=o end
        end
        if #options>0 and (not best or dist<best.distance or dist==best.distance and e.id<best.id) then best={id=e.id,entity=entity,coords=coords,distance=dist,options=options,entry=e} end
    end
    for _,e in pairs(entries) do
        if e.kind=='entity' or e.kind=='network' then
            local entity=e.kind=='entity' and e.ref or (NetworkDoesEntityExistWithNetworkId(e.ref) and NetworkGetEntityFromNetworkId(e.ref) or 0)
            if entity~=0 and DoesEntityExist(entity) then local c=GetEntityCoords(entity);consider(e,entity,c,distance(p,c),false) end
        elseif e.kind=='model' or e.kind=='global' then
            for _,entity in ipairs(pool or {}) do if DoesEntityExist(entity) then
                local typ=GetEntityType(entity);local kind=typ==2 and 'Vehicle' or typ==3 and 'Object' or typ==1 and (IsPedAPlayer(entity) and 'Player' or 'Ped')
                if entity~=PlayerPedId() and (e.kind=='model' and GetEntityModel(entity)==e.ref or e.kind=='global' and (e.ref=='All' or e.ref==kind)) then local c=GetEntityCoords(entity);consider(e,entity,c,distance(p,c),false) end
            end end
        else local yes,c=inside(e,p);if yes then consider(e,0,c,distance(p,c),true) end end
    end
    return best
end
local function execute()
    if blocked() or not active or GetGameTimer()-lastAction<350 then return end
    local current=A:collect(GetEntityCoords(PlayerPedId()),{active.entity})
    if not current or current.id~=active.id or current.entity~=active.entity then active=nil;return end
    local option=active.options[selected];local valid=false
    for _,o in ipairs(current.options) do if o==option then valid=true end end
    if not valid then active=nil;return end
    lastAction=GetGameTimer()
    local data={entity=current.entity,coords=current.coords,distance=current.distance,name=option.name,zone=current.id}
    local fn=option.onSelect or option.action
    if fn then DTUtils.safeCall(fn,data)
    elseif option.export then local resource,method=option.export:match('^([^.]+)%.(.+)$');if resource then pcall(function() local handle=exports[resource];handle[method](handle,data) end) end
    elseif option.event then TriggerEvent(option.event,data)
    elseif option.serverEvent then if data.entity~=0 then data.entity=NetworkGetEntityIsNetworked(data.entity) and NetworkGetNetworkIdFromEntity(data.entity) or 0 end;TriggerServerEvent(option.serverEvent,data)
    elseif option.command then ExecuteCommand(option.command) end
end
local function destroy()
    if dui then DestroyDui(dui) end;dui=nil;texture=nil;duiReady=false;lastPayload=nil
end
RegisterNUICallback('interactReady',function(_,cb) duiReady=true;lastPayload=nil;cb({}) end)
RegisterCommand('+dtlib_interact',execute,false);RegisterCommand('-dtlib_interact',function() end,false)
RegisterKeyMapping('+dtlib_interact','DTlib: interact','keyboard',config().key or 'E')
CreateThread(function()
    local pool,refresh={},0
    while true do
        if config().mode~='interact' or blocked() then active=nil;destroy();Wait(250)
        else
            local now=GetGameTimer();if now>=refresh then
                pool={};local scan=false;for _,e in pairs(entries) do if e.kind=='model' or e.kind=='global' then scan=true;break end end
                if scan then for _,kind in ipairs({'CPed','CVehicle','CObject'}) do for _,entity in ipairs(GetGamePool(kind)) do pool[#pool+1]=entity end end end
                refresh=now+500
            end
            local nextActive=A:collect(GetEntityCoords(PlayerPedId()),pool)
            if not nextActive or not active or active.id~=nextActive.id or active.entity~=nextActive.entity then selected=1 end
            active=nextActive;Wait(active and 100 or 250)
        end
    end
end)
CreateThread(function()
    while true do
        if active and not blocked() then
            if not dui then
                dui=CreateDui(('https://cfx-nui-%s/html/dist/interact.html'):format(GetCurrentResourceName()),352,384)
                local txd=CreateRuntimeTxd('dtlib_interaction');CreateRuntimeTextureFromDuiHandle(txd,'prompt',GetDuiHandle(dui));texture=true
            end
            if IsControlJustPressed(0,172) then selected=selected-1 end
            if IsControlJustPressed(0,173) then selected=selected+1 end
            local limit=math.max(1,math.min(5,config().maxOptions or 5));selected=((selected-1)%#active.options)+1
            local first=math.floor((selected-1)/limit)*limit+1
            local options={};for i=first,math.min(#active.options,first+limit-1) do options[#options+1]={label=active.options[i].label or active.options[i].title or 'Interact'} end
            local payload=json.encode({action='interact',data={options=options,selected=selected-first+1,key=config().key or 'E'}})
            if duiReady and payload~=lastPayload then SendDuiMessage(dui,payload);lastPayload=payload end
            local c=active.coords;local visible,x,y=GetScreenCoordFromWorldCoord(c.x,c.y,c.z+0.35)
            if visible and texture then DrawSprite('dtlib_interaction','prompt',x+0.08,y,0.19,0.26,0,255,255,255,255) end
            Wait(0)
        else
            if dui and duiReady and lastPayload then SendDuiMessage(dui,json.encode({action='interact'}));lastPayload=nil end
            Wait(100)
        end
    end
end)
AddEventHandler('onClientResourceStop',function(resource)
    for id,e in pairs(entries) do if e.owner==resource then entries[id]=nil end end
    active=nil;if resource==GetCurrentResourceName() then destroy() end
end)
DT.Modules.Register('target','dtlib_interact',A)
