local A={resource='ox_inventory',publicName='ox_inventory'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:setGetPlayerNameMethod(cb) exports.ox_inventory:setGetPlayerNameMethod(DTUtils.wrapCallable(cb)); return true end
function A:open(t,d) return exports.ox_inventory:openInventory(t,d) end
function A:useItem(d,cb) return exports.ox_inventory:useItem(d,DTUtils.wrapCallable(cb)) end
function A:useSlot(s) exports.ox_inventory:useSlot(s); return true end
function A:setStashTarget(id,owner) exports.ox_inventory:setStashTarget(id,owner); return true end
function A:getCurrentWeapon() return exports.ox_inventory:getCurrentWeapon() end
function A:displayMetadata(m,v) exports.ox_inventory:displayMetadata(m,v); return true end
function A:giveItemToTarget(s,slot,c) exports.ox_inventory:giveItemToTarget(s,slot,c); return true end
function A:weaponWheel(state) exports.ox_inventory:weaponWheel(state==true); return true end
function A:search(s,i,m) return exports.ox_inventory:Search(s,i,m) end
function A:getCount(i,m,strict) return exports.ox_inventory:GetItemCount(i,m,strict) or 0 end
function A:getItems() return exports.ox_inventory:GetPlayerItems() or {} end
function A:getWeight() return exports.ox_inventory:GetPlayerWeight() or 0 end
function A:getMaxWeight() return exports.ox_inventory:GetPlayerMaxWeight() or 0 end
function A:getSlotIdWithItem(i,m,s) return exports.ox_inventory:GetSlotIdWithItem(i,m,s) end
function A:getSlotIdsWithItem(i,m,s) return exports.ox_inventory:GetSlotIdsWithItem(i,m,s) end
function A:getSlotWithItem(i,m,s) return exports.ox_inventory:GetSlotWithItem(i,m,s) end
function A:getSlotsWithItem(i,m,s) return exports.ox_inventory:GetSlotsWithItem(i,m,s) end
function A:suppressItemNotifications(s) exports.ox_inventory:suppressItemNotifications(s==true); return true end
function A:getItemData(i) local ok,v=pcall(function() return exports.ox_inventory:Items(i) end); return ok and v or nil end
DT.Modules.Register('inventory','ox_inventory',A)
