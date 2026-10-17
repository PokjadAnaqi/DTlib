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
function DT.Inventory.SetGetPlayerNameMethod(cb) if not DTUtils.isCallable(cb) then return false,'callback_required' end; return call('setGetPlayerNameMethod',cb) end
function DT.Inventory.Open(t,d) return call('open',t,d) end
function DT.Inventory.OpenStash(id,owner) return DT.Inventory.Open('stash',owner~=nil and {id=id,owner=owner} or id) end
function DT.Inventory.UseItem(d,cb) return call('useItem',d,cb) end
function DT.Inventory.UseSlot(s) return call('useSlot',s) end
function DT.Inventory.SetStashTarget(id,owner) return call('setStashTarget',id,owner) end
function DT.Inventory.GetCurrentWeapon() return call('getCurrentWeapon') end
function DT.Inventory.DisplayMetadata(m,v) return call('displayMetadata',m,v) end
function DT.Inventory.GiveItemToTarget(s,slot,c) return call('giveItemToTarget',s,slot,c) end
function DT.Inventory.WeaponWheel(state) return call('weaponWheel',state) end
function DT.Inventory.Search(s,i,m) return call('search',s,i,m) end
function DT.Inventory.GetCount(i,m,strict) return tonumber(call('getCount',i,m,strict) or 0) or 0 end
DT.Inventory.GetItemCount=DT.Inventory.GetCount
function DT.Inventory.HasItem(i,c,m,strict) return DT.Inventory.GetCount(i,m,strict)>=(tonumber(c) or 1) end
function DT.Inventory.GetItems() return call('getItems') or {} end
DT.Inventory.GetPlayerItems=DT.Inventory.GetItems
function DT.Inventory.GetWeight() return tonumber(call('getWeight') or 0) or 0 end
function DT.Inventory.GetMaxWeight() return tonumber(call('getMaxWeight') or 0) or 0 end
function DT.Inventory.GetSlotIdWithItem(...) return call('getSlotIdWithItem',...) end
function DT.Inventory.GetSlotIdsWithItem(...) return call('getSlotIdsWithItem',...) end
function DT.Inventory.GetSlotWithItem(...) return call('getSlotWithItem',...) end
function DT.Inventory.GetSlotsWithItem(...) return call('getSlotsWithItem',...) end
function DT.Inventory.SuppressItemNotifications(state) return call('suppressItemNotifications',state) end
function DT.Inventory.IsBusy() return LocalPlayer and LocalPlayer.state and LocalPlayer.state.invBusy==true or false end
function DT.Inventory.SetBusy(state,rep) if not LocalPlayer or not LocalPlayer.state then return false end; LocalPlayer.state:set('invBusy',state==true,rep==true); return true end
function DT.Inventory.IsOpen() return LocalPlayer and LocalPlayer.state and LocalPlayer.state.invOpen==true or false end
function DT.Inventory.SetHotkeys(state,rep) if not LocalPlayer or not LocalPlayer.state then return false end; LocalPlayer.state:set('invHotkeys',state~=false,rep==true); return true end
function DT.Inventory.HotkeysEnabled() return not LocalPlayer or not LocalPlayer.state or LocalPlayer.state.invHotkeys~=false end
function DT.Inventory.SetCanUseWeapons(state,rep) if not LocalPlayer or not LocalPlayer.state then return false end; LocalPlayer.state:set('canUseWeapons',state~=false,rep==true); return true end
function DT.Inventory.CanUseWeapons() return not LocalPlayer or not LocalPlayer.state or LocalPlayer.state.canUseWeapons~=false end
function DT.Inventory.SetInstance(instance,rep) if not LocalPlayer or not LocalPlayer.state then return false end; LocalPlayer.state:set('instance',instance,rep~=false); return true end
function DT.Inventory.GetInstance() return LocalPlayer and LocalPlayer.state and LocalPlayer.state.instance or nil end
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

AddEventHandler('onClientResourceStart',function() DT.Inventory.ClearItemCache() end)
AddEventHandler('onClientResourceStop',function() DT.Inventory.ClearItemCache() end)
function DT.Inventory.Items(item)
    local value,err=call('items',item)
    if value~=nil then return value end
    if item then return DT.Inventory.GetItemData(item) end
    return nil,err or 'catalog_unavailable'
end
