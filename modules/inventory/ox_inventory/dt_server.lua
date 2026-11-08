local adapter = { resource = 'ox_inventory', publicName = 'ox_inventory' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:setPlayerInventory(...)
    exports.ox_inventory:setPlayerInventory(...)
    return true
end
function adapter:items(...)
    return exports.ox_inventory:Items(...)
end
function adapter:canCarry(...)
    return exports.ox_inventory:CanCarryItem(...)
end
function adapter:canCarryAmount(...)
    return exports.ox_inventory:CanCarryAmount(...)
end
function adapter:canCarryWeight(...)
    return exports.ox_inventory:CanCarryWeight(...)
end
function adapter:canSwapItem(...)
    return exports.ox_inventory:CanSwapItem(...)
end
function adapter:addItem(inventory, item, count, metadata, slot)
    return exports.ox_inventory:AddItem(inventory, item, count, metadata, slot)
end
function adapter:removeItem(inventory, item, count, metadata, slot, reason, ignoreTotal, strict)
    return exports.ox_inventory:RemoveItem(inventory, item, count, metadata, slot, ignoreTotal, strict)
end
function adapter:getItem(...)
    return exports.ox_inventory:GetItem(...)
end
function adapter:getCount(...)
    return exports.ox_inventory:GetItemCount(...) or 0
end
function adapter:search(...)
    return exports.ox_inventory:Search(...)
end
function adapter:getItemSlots(...)
    return exports.ox_inventory:GetItemSlots(...)
end
function adapter:getSlot(...)
    return exports.ox_inventory:GetSlot(...)
end
function adapter:getSlotForItem(...)
    return exports.ox_inventory:GetSlotForItem(...)
end
function adapter:getSlotIdWithItem(...)
    return exports.ox_inventory:GetSlotIdWithItem(...)
end
function adapter:getSlotIdsWithItem(...)
    return exports.ox_inventory:GetSlotIdsWithItem(...)
end
function adapter:getSlotWithItem(...)
    return exports.ox_inventory:GetSlotWithItem(...)
end
function adapter:getSlotsWithItem(...)
    return exports.ox_inventory:GetSlotsWithItem(...)
end
function adapter:getEmptySlot(...)
    return exports.ox_inventory:GetEmptySlot(...)
end
function adapter:getContainerFromSlot(...)
    return exports.ox_inventory:GetContainerFromSlot(...)
end
function adapter:getInventory(...)
    return exports.ox_inventory:GetInventory(...)
end
function adapter:getInventories(...)
    return exports.ox_inventory:GetInventories(...)
end
function adapter:getItems(...)
    return exports.ox_inventory:GetInventoryItems(...) or {}
end
function adapter:setMaxWeight(inventory, width)
    exports.ox_inventory:SetMaxWeight(inventory, width)
    return true
end
function adapter:setSlotCount(inventory, value)
    exports.ox_inventory:SetSlotCount(inventory, value)
    return true
end
function adapter:setMetadata(inventory, value, method)
    exports.ox_inventory:SetMetadata(inventory, value, method or {})
    return true
end
function adapter:setDurability(inventory, value, data)
    exports.ox_inventory:SetDurability(inventory, value, data)
    return true
end
function adapter:getCurrentWeapon(...)
    return exports.ox_inventory:GetCurrentWeapon(...)
end
function adapter:registerStash(...)
    exports.ox_inventory:RegisterStash(...)
    return true
end
function adapter:createTemporaryStash(...)
    return exports.ox_inventory:CreateTemporaryStash(...)
end
function adapter:customDrop(...)
    return exports.ox_inventory:CustomDrop(...)
end
function adapter:createDropFromPlayer(...)
    return exports.ox_inventory:CreateDropFromPlayer(...)
end
function adapter:setContainerProperties(...)
    exports.ox_inventory:setContainerProperties(...)
    return true
end
function adapter:clear(...)
    exports.ox_inventory:ClearInventory(...)
    return true
end
function adapter:removeInventory(...)
    exports.ox_inventory:RemoveInventory(...)
    return true
end
function adapter:forceOpen(...)
    exports.ox_inventory:forceOpenInventory(...)
    return true
end
function adapter:updateVehicle(...)
    exports.ox_inventory:UpdateVehicle(...)
    return true
end
function adapter:inspect(...)
    exports.ox_inventory:InspectInventory(...)
    return true
end
function adapter:confiscate(...)
    exports.ox_inventory:ConfiscateInventory(...)
    return true
end
function adapter:returnInventory(...)
    exports.ox_inventory:ReturnInventory(...)
    return true
end
function adapter:convertItems(...)
    return exports.ox_inventory:ConvertItems(...)
end
function adapter:getItemData(item)
    local ok, value = pcall(function()
        return exports.ox_inventory:Items(item)
    end)
    return ok and value or nil
end
DT.Modules.Register('inventory', 'ox_inventory', adapter)
