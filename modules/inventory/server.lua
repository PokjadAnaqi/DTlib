local aliases={ox='ox_inventory',dtgrid='ox_inventory',qb='qb-inventory'}
local function A()
    local candidates={'ox_inventory','qb-inventory'}
    for _,p in ipairs(DTEcosystemCatalog.inventory.providers) do if not p.default and not DTUtils.tableContains(candidates,p.resource) then candidates[#candidates+1]=p.resource end end
    return DT.Modules.Resolve('inventory',DTConfig.Adapters.inventory,candidates,aliases,'framework')
end
local function call(m,...)
    local a=A(); if not a or type(a[m])~='function' then return nil,'unsupported_backend' end; return a[m](a,...)
end
local itemCache={}
local cacheProvider,cacheFramework
local function currentProvider()
    local adapter=A()
    local framework=DT.Framework.Name and DT.Framework.Name() or ''
    if cacheProvider~=adapter or cacheFramework~=framework then
        itemCache={};cacheProvider=adapter;cacheFramework=framework
    end
    return adapter
end
function DT.Inventory.Supports(method)
    if type(method)~='string' or method=='' then return false end
    local aliases={CanCarryItem='canCarry',GetItemCount='getCount',GetInventoryItems='getItems'}
    local key=aliases[method] or method:sub(1,1):lower()..method:sub(2)
    local a=currentProvider()
    if a and a.supports then return a:supports(key)==true end
    return a~=nil and type(a[key])=='function'
end
function DT.Inventory.Name() local a=A(); return a and a.publicName or 'framework' end
function DT.Inventory.Available() local a=A(); return a and a.resource~='framework' end
function DT.Inventory.SetPlayerInventory(...) return call('setPlayerInventory',...) end
function DT.Inventory.Items(item)
    local value,err=call('items',item)
    if value~=nil then return value end
    if item then return DT.Inventory.GetItemData(item) end
    return nil,err or 'catalog_unavailable'
end
local function validCount(count)
    count=count==nil and 1 or tonumber(count)
    if not count or count~=count or count==math.huge or count<=0 or count%1~=0 then return nil end
    return count
end
function DT.Inventory.CanCarry(inv,item,count,meta)
    count=validCount(count);if not count then return false,'invalid_count' end
    return call('canCarry',inv,item,count,meta)
end
DT.Inventory.CanCarryItem=DT.Inventory.CanCarry
function DT.Inventory.CanCarryAmount(...) return call('canCarryAmount',...) end
function DT.Inventory.CanCarryWeight(...) local a,b=call('canCarryWeight',...); return a or false,b or 0 end
function DT.Inventory.CanSwapItem(...) return call('canSwapItem',...) end
function DT.Inventory.AddItem(inv,item,count,meta,slot,reason)
    count=validCount(count);if not count then return false,'invalid_count' end
    local carry,err=DT.Inventory.CanCarry(inv,item,count,meta)
    if carry==false then return false,err or 'inventory_full' end
    if carry==nil and err and err~='unsupported_backend' then return false,err end
    -- Providers without preflight must enforce capacity in their authoritative AddItem.
    return call('addItem',inv,item,count,meta,slot,reason)
end
function DT.Inventory.RemoveItem(inv,item,count,meta,slot,reason,ignore,strict)
    count=validCount(count);if not count then return false,'invalid_count' end
    return call('removeItem',inv,item,count,meta,slot,reason,ignore,strict)
end
function DT.Inventory.GetItem(inv,item,meta,returnsCount) local v=call('getItem',inv,item,meta,returnsCount); if v~=nil then return v end; if returnsCount then return DT.Inventory.GetCount(inv,item,meta) end; local d=DT.Inventory.GetItemData(type(item)=='string' and item or nil); if not d then return nil end; d=DTUtils.copy(d); d.count=DT.Inventory.GetCount(inv,item,meta); return d end
function DT.Inventory.GetCount(inv,item,meta,strict) return tonumber(call('getCount',inv,item,meta,strict) or 0) or 0 end
DT.Inventory.GetItemCount=DT.Inventory.GetCount
function DT.Inventory.HasItem(inv,item,count,meta,strict) return DT.Inventory.GetCount(inv,item,meta,strict)>=(tonumber(count) or 1) end
function DT.Inventory.Search(inv,s,item,meta) local v=call('search',inv,s,item,meta); if v~=nil then return v end; if s=='count' then return DT.Inventory.GetCount(inv,item,meta) end end
for _,m in ipairs({'GetItemSlots','GetSlot','GetSlotForItem','GetSlotIdWithItem','GetSlotIdsWithItem','GetSlotWithItem','GetSlotsWithItem','GetEmptySlot','GetContainerFromSlot','GetInventory','GetInventories'}) do local key=m:sub(1,1):lower()..m:sub(2); DT.Inventory[m]=function(...) return call(key,...) end end
function DT.Inventory.GetItems(inv,owner) return call('getItems',inv,owner) or {} end
DT.Inventory.GetInventoryItems=DT.Inventory.GetItems
function DT.Inventory.SetMaxWeight(inv,w) return call('setMaxWeight',inv,tonumber(w) or 0) end
function DT.Inventory.SetSlotCount(inv,s) return call('setSlotCount',inv,tonumber(s) or 0) end
function DT.Inventory.SetMetadata(inv,s,m) return call('setMetadata',inv,s,m or {}) end
function DT.Inventory.SetDurability(inv,s,d) return call('setDurability',inv,s,tonumber(d) or 0) end
function DT.Inventory.GetCurrentWeapon(inv) return call('getCurrentWeapon',inv) end
function DT.Inventory.RegisterStash(id,label,slots,maxWeight,owner,groups,coords,instance)
    if type(id)=='table' then local d=id; id=d.id; label=d.label; slots=d.slots; maxWeight=d.maxWeight or d.maxweight; owner=d.owner; groups=d.groups; coords=d.coords; instance=d.instance end
    return call('registerStash',id,label,slots,maxWeight,owner,groups,coords,instance)
end
function DT.Inventory.CreateTemporaryStash(...) return call('createTemporaryStash',...) end
function DT.Inventory.CustomDrop(...) return call('customDrop',...) end
function DT.Inventory.CreateDropFromPlayer(...) return call('createDropFromPlayer',...) end
function DT.Inventory.SetContainerProperties(...) return call('setContainerProperties',...) end
function DT.Inventory.Clear(...) return call('clear',...) end
DT.Inventory.ClearInventory=DT.Inventory.Clear
function DT.Inventory.RemoveInventory(...) return call('removeInventory',...) end
function DT.Inventory.ForceOpen(...) return call('forceOpen',...) end
function DT.Inventory.OpenStash(source,id,owner) return DT.Inventory.ForceOpen(source,'stash',owner~=nil and {id=id,owner=owner} or id) end
function DT.Inventory.UpdateVehicle(...) return call('updateVehicle',...) end
function DT.Inventory.Inspect(...) return call('inspect',...) end
function DT.Inventory.Confiscate(...) return call('confiscate',...) end
function DT.Inventory.Return(...) return call('returnInventory',...) end
function DT.Inventory.ConvertItems(...) return call('convertItems',...) end
function DT.Inventory.GetItemData(item)
    if type(item)~='string' or item=='' then return nil,'invalid_item' end
    local a=currentProvider()
    local cached=itemCache[item]
    if cached and GetGameTimer()-cached.at<60000 and GetGameTimer()>=cached.at then
        return DTUtils.copy(cached.data)
    end
    if not a or type(a.getItemData)~='function' then return nil,'unsupported_backend' end
    local ok,data=pcall(a.getItemData,a,item)
    if not ok then return nil,'provider_not_ready' end
    -- Never cache misses: an inventory may still be loading its definitions.
    if type(data)~='table' then return nil,'item_not_found' end
    data=DTUtils.copy(data);data.name=data.name or item
    itemCache[item]={data=data,at=GetGameTimer()}
    return DTUtils.copy(data)
end
function DT.Inventory.GetItemLabel(item) local d=DT.Inventory.GetItemData(item); local l=d and (d.label or d.displayName or d.name); return l and tostring(l) or nil end
function DT.Inventory.ClearItemCache(item) if type(item)=='string' and item~='' then itemCache[item]=nil else itemCache={} end; return true end

AddEventHandler('onResourceStart',function() DT.Inventory.ClearItemCache() end)
AddEventHandler('onResourceStop',function() DT.Inventory.ClearItemCache() end)
function DT.Inventory.RegisterUsableItem(name,callback)
    if type(name)~='string' or name=='' or not DTUtils.isCallable(callback) then return false,'invalid_usable_item' end
    return DT.Ecosystem.Call('framework','RegisterUsableItem',name,callback)
end
