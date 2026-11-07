local adapter = { resource = 'qb-inventory', publicName = 'qb-inventory' }
local function callInventoryExport(name, ...)
    local arguments = { ... }
    local ok, firstResult, secondResult, thirdResult = pcall(function()
        local handler = exports['qb-inventory'][name]
        if not handler then
            return nil
        end
        return handler(exports['qb-inventory'], table.unpack(arguments))
    end)
    if not ok then
        return nil, firstResult
    end
    return firstResult, secondResult, thirdResult
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:canCarry(inventory, item, count)
    local value, reason = callInventoryExport('CanAddItem', inventory, item, count)
    if value == nil then
        return nil, 'provider_not_ready'
    end
    return value == true, reason
end
function adapter:addItem(inventory, item, count, metadata, slot, reason)
    local completed, failureReason =
        callInventoryExport('AddItem', inventory, item, count, slot, metadata, reason or 'DTlib')
    return completed == true, failureReason
end
function adapter:removeItem(inventory, item, count, metadata, slot, reason)
    local completed, failureReason = callInventoryExport('RemoveItem', inventory, item, count, slot, reason or 'DTlib')
    return completed == true, failureReason
end
function adapter:getCount(inventory, item)
    local result = callInventoryExport('GetItemByName', inventory, item)
    return result and (result.amount or result.count or 0) or 0
end
function adapter:getSlot(inventory, slot)
    return callInventoryExport('GetItemBySlot', inventory, slot)
end
function adapter:getItems(inventory)
    local player = type(inventory) == 'number' and DT.Player.Get(inventory) or nil
    return player and player.PlayerData and player.PlayerData.items or {}
end
function adapter:registerStash(id, label, slots, maxWeight)
    local result = callInventoryExport('CreateInventory', id, { label = label, maxweight = maxWeight, slots = slots })
    return result ~= nil
end
function adapter:clear(inventory, keep)
    local result = callInventoryExport('ClearInventory', inventory, keep)
    return result ~= nil
end
function adapter:forceOpen(playerId, invType, data)
    if invType ~= 'stash' then
        return false
    end
    local result = callInventoryExport('OpenInventory', playerId, type(data) == 'table' and data.id or data)
    return result ~= nil
end
function adapter:items(item)
    return DT.Modules.Get('inventory', 'framework'):items(item)
end
function adapter:getItemData(item)
    return self:items(item)
end
DT.Modules.Register('inventory', 'qb-inventory', adapter)
