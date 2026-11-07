local adapter = { resource = 'ox_inventory', publicName = 'ox_inventory' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:setGetPlayerNameMethod(callback)
    exports.ox_inventory:setGetPlayerNameMethod(DTUtils.wrapCallable(callback))
    return true
end
function adapter:open(inventoryType, data)
    return exports.ox_inventory:openInventory(inventoryType, data)
end
function adapter:useItem(data, callback)
    return exports.ox_inventory:useItem(data, DTUtils.wrapCallable(callback))
end
function adapter:useSlot(value)
    exports.ox_inventory:useSlot(value)
    return true
end
function adapter:setStashTarget(id, owner)
    exports.ox_inventory:setStashTarget(id, owner)
    return true
end
function adapter:getCurrentWeapon()
    return exports.ox_inventory:getCurrentWeapon()
end
function adapter:displayMetadata(method, value)
    exports.ox_inventory:displayMetadata(method, value)
    return true
end
function adapter:giveItemToTarget(value, slot, coreObject)
    exports.ox_inventory:giveItemToTarget(value, slot, coreObject)
    return true
end
function adapter:weaponWheel(state)
    exports.ox_inventory:weaponWheel(state == true)
    return true
end
function adapter:search(value, index, method)
    return exports.ox_inventory:Search(value, index, method)
end
function adapter:getCount(index, method, strict)
    return exports.ox_inventory:GetItemCount(index, method, strict) or 0
end
function adapter:getItems()
    return exports.ox_inventory:GetPlayerItems() or {}
end
function adapter:getWeight()
    return exports.ox_inventory:GetPlayerWeight() or 0
end
function adapter:getMaxWeight()
    return exports.ox_inventory:GetPlayerMaxWeight() or 0
end
function adapter:getSlotIdWithItem(index, method, value)
    return exports.ox_inventory:GetSlotIdWithItem(index, method, value)
end
function adapter:getSlotIdsWithItem(index, method, value)
    return exports.ox_inventory:GetSlotIdsWithItem(index, method, value)
end
function adapter:getSlotWithItem(index, method, value)
    return exports.ox_inventory:GetSlotWithItem(index, method, value)
end
function adapter:getSlotsWithItem(index, method, value)
    return exports.ox_inventory:GetSlotsWithItem(index, method, value)
end
function adapter:suppressItemNotifications(value)
    exports.ox_inventory:suppressItemNotifications(value == true)
    return true
end
function adapter:getItemData(index)
    local ok, value = pcall(function()
        return exports.ox_inventory:Items(index)
    end)
    return ok and value or nil
end
function adapter:items(item)
    return exports.ox_inventory:Items(item)
end
DT.Modules.Register('inventory', 'ox_inventory', adapter)
