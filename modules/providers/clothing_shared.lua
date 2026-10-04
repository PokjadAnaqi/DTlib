local P=DT.Providers
local fields={
    ['qb-clothing']={components={[1]='mask',[2]='hair',[3]='arms',[4]='pants',[5]='bag',[6]='shoes',[7]='accessory',[8]='t-shirt',[9]='vest',[10]='decals',[11]='torso2'},props={[0]='hat',[1]='glass',[2]='ear',[6]='watch',[7]='bracelet'}},
    esx_skin={components={[1]='mask',[2]='hair',[3]='arms',[4]='pants',[5]='bags',[6]='shoes',[7]='chain',[8]='tshirt',[9]='bproof',[10]='decals',[11]='torso'},props={[0]='helmet',[1]='glasses',[2]='ears',[6]='watches',[7]='bracelets'}}
}
local function convert(resource,data,toVendor)
    local schema=fields[resource];if not schema then return DTUtils.copy(data) end
    local result={model=data.model}
    if not toVendor then result.components={};result.props={} end
    for _,kind in ipairs({'components','props'}) do
        for id,key in pairs(schema[kind]) do
            if toVendor then
                for _,entry in pairs(data[kind] or {}) do
                    if entry[kind=='components' and 'component_id' or 'prop_id']==id then
                        if resource=='esx_skin' then result[key..'_1']=entry.drawable;result[key..'_2']=entry.texture or 0
                        else result[key]={item=entry.drawable,texture=entry.texture or 0} end
                    end
                end
            else
                local value=data[key];local drawable=resource=='esx_skin' and data[key..'_1'] or type(value)=='table' and value.item
                local texture=resource=='esx_skin' and data[key..'_2'] or type(value)=='table' and value.texture
                if drawable~=nil then result[kind][#result[kind]+1]={[kind=='components' and 'component_id' or 'prop_id']=id,drawable=drawable,texture=texture or 0} end
            end
        end
    end
    return result
end
local function snapshot()
    local ped=PlayerPedId();local result={model=GetEntityModel(ped),components={},props={}}
    for id=0,11 do result.components[#result.components+1]={component_id=id,drawable=GetPedDrawableVariation(ped,id),texture=GetPedTextureVariation(ped,id),palette=GetPedPaletteVariation(ped,id)} end
    for _,id in ipairs({0,1,2,6,7}) do result.props[#result.props+1]={prop_id=id,drawable=GetPedPropIndex(ped,id),texture=GetPedPropTextureIndex(ped,id)} end
    return result
end
local function apply(data)
    local ped=PlayerPedId()
    if data.model and GetEntityModel(ped)~=data.model then
        local hash=type(data.model)=='string' and joaat(data.model) or data.model
        if not IsModelInCdimage(hash) or not IsModelValid(hash) then return false,'invalid_model' end
        RequestModel(hash);local untilTime=GetGameTimer()+10000
        while not HasModelLoaded(hash) do if GetGameTimer()>untilTime then return false,'model_timeout' end;Wait(0) end
        SetPlayerModel(PlayerId(),hash);SetModelAsNoLongerNeeded(hash);ped=PlayerPedId()
    end
    for _,entry in pairs(data.components or {}) do SetPedComponentVariation(ped,entry.component_id,entry.drawable,entry.texture or 0,entry.palette or 0) end
    for _,entry in pairs(data.props or {}) do if entry.drawable<0 then ClearPedProp(ped,entry.prop_id) else SetPedPropIndex(ped,entry.prop_id,entry.drawable,entry.texture or 0,true) end end
    return true
end
for _,definition in ipairs(DTEcosystemCatalog.clothing.providers) do
    P.Register('clothing',definition.resource,function(resource)
        local api={ConvertFromDefault=function(data) return convert(resource,data,true) end,ConvertToDefault=function(data) return convert(resource,data,false) end}
        api.ConvertData=api.ConvertToDefault
        local appearance=resource=='illenium-appearance' or resource=='fivem-appearance'
        if P.Server then
            local backup={}
            function api.GetFullAppearanceData(src) return DT.Callback.AwaitClient(src,'DTlib:provider:appearanceGet',resource) end
            api.GetAppearance=api.GetFullAppearanceData
            if resource=='esx_skin' then function api.Save(src)
                local id=DT.Player.GetIdentifier(src);if not id then return false,'player_not_found' end
                local skin=DT.Callback.AwaitClient(src,'DTlib:provider:skinGet')
                if type(skin)~='table' then return false,'appearance_unavailable' end
                return (DT.Database.Update('UPDATE users SET skin = ? WHERE identifier = ?',{json.encode(skin),id}) or 0)>0
            end end
            function api.IsMale(src) local data=api.GetAppearance(src);return data and data.model==joaat('mp_m_freemode_01') end
            function api.SetAppearance(src,data,updateBackup,save)
                if save and not api.Save then return false,'use_vendor_save_api' end
                if not backup[src] or updateBackup then backup[src]=api.GetAppearance(src) end
                local ok,reason=DT.Callback.AwaitClient(src,'DTlib:provider:appearanceSet',resource,data)
                if ok==false then return false,reason end
                if save then return api.Save(src) end
                return ok,reason
            end
            function api.SetAppearanceExt(src,data) return api.SetAppearance(src,data,false,false) end
            function api.Revert(src) if not backup[src] then return false,'no_backup' end;local data=backup[src];backup[src]=nil;return DT.Callback.AwaitClient(src,'DTlib:provider:appearanceSet',resource,data) end
            api.RestoreAppearance=api.Revert
            function api.OpenMenu(src) TriggerClientEvent('DTlib:provider:clothingOpen',src,resource);return true end
            AddEventHandler('playerDropped',function() backup[source]=nil end)
            return api
        end
        local backup
        function api.GetFullAppearanceData()
            if appearance then return P.Export(resource,'getPedAppearance',PlayerPedId()) end
            return snapshot()
        end
        api.GetAppearance=api.GetFullAppearanceData
        function api.IsMale() return GetEntityModel(PlayerPedId())==joaat('mp_m_freemode_01') end
        function api.SetAppearance(data,updateBackup,save)
            if save then return false,'use_vendor_save_api' end
            if not backup or updateBackup then backup=api.GetAppearance() end
            if appearance then P.Export(resource,'setPedAppearance',PlayerPedId(),data);return true end
            if resource=='esx_skin' then
                local skin=P.WaitCallback(function(done) TriggerEvent('skinchanger:getSkin',done) end)
                local changes=convert(resource,data,true);for key,value in pairs(changes) do if key~='model' then skin[key]=value end end
                TriggerEvent('skinchanger:loadSkin',skin)
                return true
            end
            return apply(data)
        end
        api.SetAppearanceExt=api.SetAppearance
        function api.Revert() if not backup then return false,'no_backup' end;local data=backup;backup=nil;if appearance then return P.Export(resource,'setPedAppearance',PlayerPedId(),data) end;return apply(data) end
        api.RestoreAppearance=api.Revert
        function api.OpenMenu(options)
            if resource=='fivem-appearance' then return P.WaitCallback(function(done) P.Export(resource,'startPlayerCustomization',done,options or {}) end) end
            if resource=='esx_skin' then TriggerEvent('esx_skin:openMenu',function() end,function() end,true);return true end
            if resource~='native' then TriggerEvent('qb-clothing:client:openMenu');return true end
            return nil,'no_native_clothing_editor'
        end
        return api
    end)
end
if not P.Server then
    DT.Callback.Register('DTlib:provider:skinGet',function() return P.WaitCallback(function(done) TriggerEvent('skinchanger:getSkin',done) end) end)
    DT.Callback.Register('DTlib:provider:appearanceGet',function(resource) local api=DT.Ecosystem.Get('clothing',resource);return api and api.GetAppearance() end)
    DT.Callback.Register('DTlib:provider:appearanceSet',function(resource,data) local api=DT.Ecosystem.Get('clothing',resource);return api and api.SetAppearance(data) end)
    RegisterNetEvent('DTlib:provider:clothingOpen',function(resource) if source~=65535 then return end;local api=DT.Ecosystem.Get('clothing',resource);if api then api.OpenMenu() end end)
end
