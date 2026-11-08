local adapter = { resource = 'framework', publicName = 'framework' }
function adapter:available()
    return true
end
function adapter:getItems()
    local data = DT.Player.GetData and DT.Player.GetData() or {}
    return data.items or {}
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
