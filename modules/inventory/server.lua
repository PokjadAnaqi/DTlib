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
function DT.Inventory.Name() local a=A(); return a and a.publicName or 'framework' end
function DT.Inventory.Available() local a=A(); return a and a.resource~='framework' end
function DT.Inventory.SetPlayerInventory(...) return call('setPlayerInventory',...) end
function DT.Inventory.Items(item) local v=call('items',item); return v or (item and DT.Inventory.GetItemData(item)) end
function DT.Inventory.CanCarry(inv,item,count,meta) count=tonumber(count) or 1; local v=call('canCarry',inv,item,count,meta); return v==nil and true or v end
DT.Inventory.CanCarryItem=DT.Inventory.CanCarry
function DT.Inventory.CanCarryAmount(...) return call('canCarryAmount',...) end
function DT.Inventory.CanCarryWeight(...) local a,b=call('canCarryWeight',...); return a or false,b or 0 end
function DT.Inventory.CanSwapItem(...) return call('canSwapItem',...) end
function DT.Inventory.AddItem(inv,item,count,meta,slot,reason) count=tonumber(count) or 1; if not DT.Inventory.CanCarry(inv,item,count,meta) then return false,'inventory_full' end; return call('addItem',inv,item,count,meta,slot,reason) end
function DT.Inventory.RemoveItem(inv,item,count,meta,slot,reason,ignore,strict) return call('removeItem',inv,item,tonumber(count) or 1,meta,slot,reason,ignore,strict) end
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
    if type(item)~='string' or item=='' then return nil end; if itemCache[item]~=nil then return itemCache[item] or nil end
    local d=call('getItemData',item); if type(d)=='table' then d.name=d.name or item; itemCache[item]=d; return d end; itemCache[item]=false
end
function DT.Inventory.GetItemLabel(item) local d=DT.Inventory.GetItemData(item); local l=d and (d.label or d.displayName or d.name); return l and tostring(l) or nil end
function DT.Inventory.ClearItemCache(item) if type(item)=='string' and item~='' then itemCache[item]=nil else itemCache={} end; return true end
