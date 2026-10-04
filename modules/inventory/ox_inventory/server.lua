local A={resource='ox_inventory',publicName='ox_inventory'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:setPlayerInventory(...) exports.ox_inventory:setPlayerInventory(...); return true end
function A:items(...) return exports.ox_inventory:Items(...) end
function A:canCarry(...) return exports.ox_inventory:CanCarryItem(...) end
function A:canCarryAmount(...) return exports.ox_inventory:CanCarryAmount(...) end
function A:canCarryWeight(...) return exports.ox_inventory:CanCarryWeight(...) end
function A:canSwapItem(...) return exports.ox_inventory:CanSwapItem(...) end
function A:addItem(inv,item,count,metadata,slot) return exports.ox_inventory:AddItem(inv,item,count,metadata,slot) end
function A:removeItem(inv,item,count,metadata,slot,reason,ignoreTotal,strict) return exports.ox_inventory:RemoveItem(inv,item,count,metadata,slot,ignoreTotal,strict) end
function A:getItem(...) return exports.ox_inventory:GetItem(...) end
function A:getCount(...) return exports.ox_inventory:GetItemCount(...) or 0 end
function A:search(...) return exports.ox_inventory:Search(...) end
function A:getItemSlots(...) return exports.ox_inventory:GetItemSlots(...) end
function A:getSlot(...) return exports.ox_inventory:GetSlot(...) end
function A:getSlotForItem(...) return exports.ox_inventory:GetSlotForItem(...) end
function A:getSlotIdWithItem(...) return exports.ox_inventory:GetSlotIdWithItem(...) end
function A:getSlotIdsWithItem(...) return exports.ox_inventory:GetSlotIdsWithItem(...) end
function A:getSlotWithItem(...) return exports.ox_inventory:GetSlotWithItem(...) end
function A:getSlotsWithItem(...) return exports.ox_inventory:GetSlotsWithItem(...) end
function A:getEmptySlot(...) return exports.ox_inventory:GetEmptySlot(...) end
function A:getContainerFromSlot(...) return exports.ox_inventory:GetContainerFromSlot(...) end
function A:getInventory(...) return exports.ox_inventory:GetInventory(...) end
function A:getInventories(...) return exports.ox_inventory:GetInventories(...) end
function A:getItems(...) return exports.ox_inventory:GetInventoryItems(...) or {} end
function A:setMaxWeight(inv,w) exports.ox_inventory:SetMaxWeight(inv,w); return true end
function A:setSlotCount(inv,s) exports.ox_inventory:SetSlotCount(inv,s); return true end
function A:setMetadata(inv,s,m) exports.ox_inventory:SetMetadata(inv,s,m or {}); return true end
function A:setDurability(inv,s,d) exports.ox_inventory:SetDurability(inv,s,d); return true end
function A:getCurrentWeapon(...) return exports.ox_inventory:GetCurrentWeapon(...) end
function A:registerStash(...) exports.ox_inventory:RegisterStash(...); return true end
function A:createTemporaryStash(...) return exports.ox_inventory:CreateTemporaryStash(...) end
function A:customDrop(...) return exports.ox_inventory:CustomDrop(...) end
function A:createDropFromPlayer(...) return exports.ox_inventory:CreateDropFromPlayer(...) end
function A:setContainerProperties(...) exports.ox_inventory:setContainerProperties(...); return true end
function A:clear(...) exports.ox_inventory:ClearInventory(...); return true end
function A:removeInventory(...) exports.ox_inventory:RemoveInventory(...); return true end
function A:forceOpen(...) exports.ox_inventory:forceOpenInventory(...); return true end
function A:updateVehicle(...) exports.ox_inventory:UpdateVehicle(...); return true end
function A:inspect(...) exports.ox_inventory:InspectInventory(...); return true end
function A:confiscate(...) exports.ox_inventory:ConfiscateInventory(...); return true end
function A:returnInventory(...) exports.ox_inventory:ReturnInventory(...); return true end
function A:convertItems(...) return exports.ox_inventory:ConvertItems(...) end
function A:getItemData(item) local ok,v=pcall(function() return exports.ox_inventory:Items(item) end); return ok and v or nil end
DT.Modules.Register('inventory','ox_inventory',A)
