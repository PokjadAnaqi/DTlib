local adapter = { resource = 'framework', publicName = 'framework' }
function adapter:available()
    return true
end
function adapter:addItem(inventory, item, count, metadata, slot)
    local inventoryPlayer = type(inventory) == 'number' and DT.Player.Get(inventory) or nil
    return inventoryPlayer
            and inventoryPlayer.Functions
            and inventoryPlayer.Functions.AddItem
            and inventoryPlayer.Functions.AddItem(item, count, slot, metadata)
        or false,
        'no_inventory_backend'
end
function adapter:removeItem(inventory, item, count, metadata, slot)
    local inventoryPlayer = type(inventory) == 'number' and DT.Player.Get(inventory) or nil
    return inventoryPlayer
            and inventoryPlayer.Functions
            and inventoryPlayer.Functions.RemoveItem
            and inventoryPlayer.Functions.RemoveItem(item, count, slot)
        or false,
        'no_inventory_backend'
end
function adapter:getCount(inventory, item)
    local player = type(inventory) == 'number' and DT.Player.Get(inventory) or nil
    local name = 0
    for _, itemEntry in pairs(player and player.PlayerData and player.PlayerData.items or {}) do
        if itemEntry and itemEntry.name == item then
            name = name + (itemEntry.amount or itemEntry.count or 0)
        end
    end
    return name
end
function adapter:getItems(inventory)
    local player = type(inventory) == 'number' and DT.Player.Get(inventory) or nil
    return player and player.PlayerData and player.PlayerData.items or {}
end
function adapter:items(item)
    local ok, items = pcall(function()
        if DTUtils.isStarted('qb-core') then
            local core = exports['qb-core']:GetCoreObject()
            return core and core.Shared and core.Shared.Items
        end
        if DTUtils.isStarted('es_extended') then
            local esx = exports.es_extended:getSharedObject()
            return esx and esx.Items
        end
    end)
    if not ok or type(items) ~= 'table' then
        return nil, 'catalog_unavailable'
    end
    if item then
        return items[item]
    end
    return items
end
function adapter:getItemData(item)
    return self:items(item)
end
DT.Modules.Register('inventory', 'framework', adapter)
