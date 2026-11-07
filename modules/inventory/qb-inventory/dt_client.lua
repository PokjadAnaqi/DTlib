local adapter = { resource = 'qb-inventory', publicName = 'qb-inventory' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:open(inventoryType, data)
    local ok, value = pcall(function()
        return exports['qb-inventory']:OpenInventory(inventoryType, data)
    end)
    return ok and value or false
end
function adapter:getItems()
    local data = DT.Player.GetData and DT.Player.GetData() or {}
    return data.items or {}
end
function adapter:items(item)
    return DT.Modules.Get('inventory', 'framework'):items(item)
end
function adapter:getItemData(item)
    return self:items(item)
end
DT.Modules.Register('inventory', 'qb-inventory', adapter)
