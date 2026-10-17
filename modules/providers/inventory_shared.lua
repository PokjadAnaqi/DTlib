local P=DT.Providers
-- Public export names and argument conventions, with no external Lua loader.
local specs={
    ox_inventory={items='Items',count='GetItemCount',inventory='GetInventoryItems',slot='GetSlot',carry='CanCarryItem',add='AddItem',remove='RemoveItem',order='meta'},
    ['qb-inventory']={slot='GetItemBySlot',carry='CanAddItem',add='AddItem',remove='RemoveItem',order='slot'},
    ['qs-inventory']={items='GetItemList',count='GetItemTotalAmount',inventory='GetInventory',carry='CanCarryItem',add='AddItem',remove='RemoveItem',order='slot'},
    ['codem-inventory']={items='GetItemList',count='GetItemsTotalAmount',slot='GetItemBySlot',add='AddItem',remove='RemoveItem',order='slot'},
    core_inventory={items='getItemsList',count='getItemCount',inventory='getInventory',add='addItem',remove='removeItem',order='meta'},
    ['jpr-inventory']={slot='GetItemBySlot',carry='CanCarryItem',add='AddItem',remove='RemoveItem',order='slot'},
    one_inventory={items='GetAllItemDefinitions',count='GetItemCount',inventory='GetInventoryItems',slot='GetSlot',carry='CanCarryItem',add='AddItem',remove='RemoveItem',order='meta'},
    origen_inventory={items='Items',count='getItemCount',inventory='GetInventory',carry='canCarryItem',add='addItem',remove='removeItem',order='meta'},
    ['ps-inventory']={slot='GetItemBySlot',add='AddItem',remove='RemoveItem',order='slot'},
    ['tgiann-inventory']={items='GetItemList',inventory='GetPlayerItems',slot='GetItemBySlot',carry='CanCarryItem',add='AddItem',remove='RemoveItem',order='slot'}
}
local function frameworkItems(src)
    local data=P.Server and DT.Player.GetData(src) or DT.Player.GetData()
    return data.items or data.inventory or {}
end
local function definitions(resource,spec)
    if spec and spec.items then return P.Export(resource,spec.items) end
    if GetResourceState('qb-core')=='started' then return P.Export('qb-core','GetCoreObject').Shared.Items end
    if GetResourceState('qbx_core')=='started' then return P.Export('qbx_core','GetItems') end
    return {}
end
for _,definition in ipairs(DTEcosystemCatalog.inventory.providers) do
    P.Register('inventory',definition.resource,function(resource)
        local spec=specs[resource] or {order='framework'}
        local api={};local stashes={}
        function api.Items(item) local all=definitions(resource,spec);if type(all)~='table' then return nil,'catalog_unavailable' end;if item then return all[item] end;return all end
        api.GetItemInfo=api.Items
        function api.GetPlayerInventory(src)
            if resource=='codem-inventory' and P.Server then return P.Export(resource,'GetInventory',DT.Player.GetIdentifier(src),src) end
            if not P.Server then
                local client={ox_inventory='GetPlayerItems',['qs-inventory']='getUserInventory',['codem-inventory']='GetClientPlayerInventory',core_inventory='getInventory',one_inventory='GetInventoryItems',origen_inventory='GetInventory',['tgiann-inventory']='GetPlayerItems'}
                if client[resource] then return P.Export(resource,client[resource]) end
                return frameworkItems()
            end
            if spec.inventory then return P.Export(resource,spec.inventory,src) end
            return frameworkItems(src)
        end
        function api.GetItemCount(src,item,metadata)
            if not P.Server then item,metadata=src,item
                if resource=='ox_inventory' or resource=='origen_inventory' then return P.Export(resource,'Search','count',item,metadata) end
                if resource=='qs-inventory' then return P.Export(resource,'Search',item) end
                if resource=='tgiann-inventory' then return P.Export(resource,'GetItemCount',item,metadata,false) end
                if resource=='core_inventory' or resource=='one_inventory' then return P.Export(resource,spec.count,item,metadata) end
            elseif spec.count then return P.Export(resource,spec.count,src,item,metadata,false) end
            local total=0
            for _,entry in pairs(api.GetPlayerInventory(src) or {}) do if entry.name==item then total=total+(entry.count or entry.amount or 0) end end
            return total
        end
        function api.HasItem(src,item,count,metadata)
            if not P.Server then return (api.GetItemCount(src,count) or 0)>=(tonumber(item) or 1) end
            return (api.GetItemCount(src,item,metadata) or 0)>=(tonumber(count) or 1)
        end
        function api.GetItemBySlot(src,slot)
            if P.Server and spec.slot then return P.Export(resource,spec.slot,src,slot) end
            if not P.Server then slot=src end
            for key,entry in pairs(api.GetPlayerInventory(P.Server and src or nil) or {}) do if entry.slot==slot or key==slot then return entry end end
        end
        function api.GetImagePath(item)
            local info=api.Items(item) or {}
            local folders={ox_inventory='web/images/',one_inventory='web/images/',origen_inventory='html/images/',core_inventory='html/img/',['codem-inventory']='html/itemimages/',['tgiann-inventory']='images/'}
            local imageResource=resource=='native' and 'qb-inventory' or resource=='tgiann-inventory' and 'inventory_images' or resource
            return 'nui://'..imageResource..'/'..(folders[resource] or 'html/images/')..(info.image or tostring(item)..'.png')
        end
        api.StripPNG=function(value) return tostring(value):gsub('%.png$','') end
        api.StripWebp=function(value) return tostring(value):gsub('%.webp$','') end
        if not P.Server then return api end
        for _,operation in ipairs({'AddItem','RemoveItem'}) do
            local exportName=operation=='AddItem' and spec.add or spec.remove
            api[operation]=function(src,item,count,slot,metadata)
                count=tonumber(count)
                if not count or count<=0 or count%1~=0 then return false,'invalid_count' end
                if spec.order=='framework' then
                    local player=DT.Player.Get(src)
                    if player and player.addInventoryItem then
                        if operation=='AddItem' then player.addInventoryItem(item,count) else player.removeInventoryItem(item,count) end
                        return true
                    end
                    local adapter=DT.Modules.Get('inventory','framework')
                    return adapter[operation=='AddItem' and 'addItem' or 'removeItem'](adapter,src,item,count,metadata,slot)
                end
                if resource=='core_inventory' and operation=='RemoveItem' and slot then return P.Export(resource,'removeItemExact',src,slot,count) end
                if resource=='origen_inventory' then return P.Export(resource,exportName,src,item,count,metadata,slot,false) end
                if spec.order=='meta' then return P.Export(resource,exportName,src,item,count,metadata,slot) end
                if resource=='codem-inventory' and operation=='RemoveItem' then return P.Export(resource,exportName,src,item,count,slot) end
                if (resource=='qb-inventory' or resource=='jpr-inventory' or resource=='ps-inventory') and operation=='RemoveItem' then return P.Export(resource,exportName,src,item,count,slot,'DTlib') end
                if resource=='tgiann-inventory' then return P.Export(resource,exportName,src,item,count,slot,metadata,false) end
                return P.Export(resource,exportName,src,item,count,slot,metadata,'DTlib')
            end
        end
        if spec.carry then api.CanCarryItem=P.Bind(resource,spec.carry) end
        if resource=='native' then api.CanCarryItem=function(src,item,count)
            local player=DT.Player.Get(src)
            if player and player.canCarryItem then return player.canCarryItem(item,count) end
            return nil,'carry_check_unavailable'
        end end
        local metadataExports={ox_inventory='SetMetadata',['qs-inventory']='SetItemMetadata',['codem-inventory']='SetItemMetadata',core_inventory='setMetadata',one_inventory='SetItemMetadata',origen_inventory='setMetadata'}
        if metadataExports[resource] then api.SetMetadata=function(src,item,slot,metadata) return P.Export(resource,metadataExports[resource],src,slot,metadata) end end
        if resource=='tgiann-inventory' then api.SetMetadata=P.Bind(resource,'UpdateItemMetadata') end
        local stashExports={ox_inventory='RegisterStash',origen_inventory='registerStash'}
        if stashExports[resource] then api.RegisterStash=P.Bind(resource,stashExports[resource]) end
        if resource=='qb-inventory' then api.RegisterStash=function(id,label,slots,weight) return P.Export(resource,'CreateInventory',id,{label=label,slots=slots,maxweight=weight}) end end
        if resource=='core_inventory' or resource=='qs-inventory' or resource=='jpr-inventory' then
            api.RegisterStash=function(id,label,slots,weight,owner,groups,coords) stashes[id]={label=label,slots=slots or 30,maxWeight=weight or 50000,owner=owner,groups=groups,coords=coords};return true,id end
        end
        local clearExports={ox_inventory='ClearInventory',one_inventory='ClearInventory',['qb-inventory']='ClearStash'}
        if clearExports[resource] then api.ClearStash=P.Bind(resource,clearExports[resource]) end
        if resource=='qs-inventory' then api.ClearStash=function(id,kind) return P.Export(resource,'ClearOtherInventory',kind or 'stash',id) end end
        if resource=='tgiann-inventory' then api.ClearStash=function(id,kind) return P.Export(resource,'DeleteInventory',kind or 'stash',id) end end
        if resource=='codem-inventory' then
            api.ClearStash=function(id) return P.Export(resource,'UpdateStash',id,{}) end
            api.AddStashItems=function(id,items)
                local rows={};for i,item in ipairs(items) do local name=item.name or item.item;local info=api.Items(name) or {};rows[i]={item=name,amount=item.count or item.amount,info=item.metadata or item.info or {},slot=item.slot or i,weight=info.weight or 0,unique=info.unique or false,type=info.type or 'item',description=info.description or ''} end
                return P.Export(resource,'UpdateStash',id,rows)
            end
        end
        function api.OpenStash(src,kind,id,options)
            kind=kind or 'stash'
            if resource=='ox_inventory' then return P.Export(resource,'forceOpenInventory',src,kind,id) end
            if resource=='one_inventory' then return P.Export(resource,'OpenInventory',src,kind,{id=id}) end
            if resource=='origen_inventory' then return P.Export(resource,'OpenInventory',src,kind,id) end
            if resource=='qb-inventory' then return P.Export(resource,'OpenInventory',src,id,options) end
            if resource=='ps-inventory' then return P.Export(resource,'OpenInventory',kind,id,options,src) end
            if resource=='tgiann-inventory' then return P.Export(resource,'ForceOpenInventory',src,kind,id,options) end
            if resource=='core_inventory' then options=options or stashes[id] or {};return P.Export(resource,'openInventory',src,id,kind,options.slots,options.maxWeight,true,nil,false) end
            if resource=='qs-inventory' or resource=='jpr-inventory' then
                options=options or stashes[id];if not options then return false,'stash_not_registered' end
                if options.groups and not DT.Player.HasGroup(src,options.groups) then return false,'access_denied' end
                TriggerClientEvent('DTlib:provider:legacyStash',src,resource,kind,id,{maxweight=options.maxWeight,slots=options.slots});return true
            end
            return nil,'unsupported_method:OpenStash'
        end
        if resource=='ox_inventory' then
            api.OpenPlayerInventory=function(src,target) return api.OpenStash(src,'player',target) end
        elseif resource=='one_inventory' then api.OpenPlayerInventory=function(src,target) return P.Export(resource,'OpenInventory',src,'player:',target) end
        elseif resource=='origen_inventory' then api.OpenPlayerInventory=function(src,target) return P.Export(resource,'OpenInventory',src,'otherplayer',target) end
        elseif resource=='qb-inventory' then api.OpenPlayerInventory=P.Bind(resource,'OpenInventory')
        elseif resource=='core_inventory' then api.OpenPlayerInventory=function(src,target) local id=DT.Player.GetIdentifier(target);if not id then return false,'player_not_found' end;return P.Export(resource,'openInventory',src,'stash-'..id:gsub(':',''),'stash',nil,nil,true,nil,false) end
        elseif resource=='jpr-inventory' then api.OpenPlayerInventory=function(src,target) return P.Export(resource,'OpenInventory',src,DT.Player.GetIdentifier(target)) end
        elseif resource=='ps-inventory' or resource=='tgiann-inventory' then api.OpenPlayerInventory=P.Bind(resource,'OpenInventoryById') end
        local plateExports={ox_inventory='UpdateVehicle',one_inventory='UpdateVehiclePlate',['tgiann-inventory']='UpdateVehicle'}
        if plateExports[resource] then api.UpdatePlate=P.Bind(resource,plateExports[resource]) end
        if resource=='ox_inventory' then
            api.RegisterShop=function(id,items,coords,groups) return P.Export(resource,'RegisterShop',id,{name=id,inventory=items,groups=groups}) end
            api.OpenShop=function(src,id) return api.OpenStash(src,'shop',{type=id,id=1}) end
        elseif resource=='qb-inventory' or resource=='ps-inventory' or resource=='jpr-inventory' then
            api.RegisterShop=function(id,items,coords,groups)
                local rows={};for i,item in ipairs(items) do rows[i]={name=item.name,price=item.price,amount=item.count or item.amount or 1000,slot=i,info=item.metadata or item.info} end
                return P.Export(resource,'CreateShop',{name=id,label=id,items=rows,slots=#rows,coords=coords,groups=groups})
            end
            api.OpenShop=P.Bind(resource,'OpenShop')
        end
        if resource=='one_inventory' then api.OpenShop=function(src,id) return P.Export(resource,'OpenInventory',src,'shop',id) end end
        if spec.add and (resource=='ox_inventory' or resource=='one_inventory' or resource=='origen_inventory' or resource=='qb-inventory') then
            api.AddStashItems=function(id,items)
                for _,item in ipairs(items) do local ok,reason=api.AddItem(id,item.name or item.item,item.count or item.amount or 1,item.slot,item.metadata or item.info);if not ok then return false,reason end end
                return true
            end
            api.AddTrunkItems=function(plate,items) local prefix=resource=='one_inventory' and 'vehicle:trunk:' or resource=='origen_inventory' and 'trunk_' or resource=='qb-inventory' and 'trunk-' or 'trunk';return api.AddStashItems(prefix..plate,items) end
        end
        if resource=='tgiann-inventory' then api.AddTrunkItems=function(plate,items)
            for _,item in ipairs(items) do local ok=P.Export(resource,'AddItemToSecondaryInventory','trunk',plate,item.name or item.item,item.count or item.amount,nil,item.metadata or item.info);if ok==false then return false end end;return true
        end end
        if P.InventoryExtras then P.InventoryExtras(api,resource) end
        return api
    end)
end
if not P.Server then RegisterNetEvent('DTlib:provider:legacyStash',function(resource,kind,id,options)
    if source~=65535 or (resource~='qs-inventory' and resource~='jpr-inventory') then return end
    TriggerServerEvent('inventory:server:OpenInventory',kind,id,options)
    TriggerEvent('inventory:client:SetCurrentStash',id)
end) end
