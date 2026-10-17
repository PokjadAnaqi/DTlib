local A={resource='framework',publicName='framework'}
function A:available() return true end
function A:getItems() local d=DT.Player.GetData and DT.Player.GetData() or {}; return d.items or {} end
function A:items(item)
    local ok,items=pcall(function()
        if DTUtils.isStarted('qb-core') then
            local core=exports['qb-core']:GetCoreObject()
            return core and core.Shared and core.Shared.Items
        end
        if DTUtils.isStarted('es_extended') then
            local esx=exports.es_extended:getSharedObject()
            return esx and esx.Items
        end
    end)
    if not ok or type(items)~='table' then return nil,'catalog_unavailable' end
    if item then return items[item] end
    return items
end
function A:getItemData(item) return self:items(item) end
DT.Modules.Register('inventory','framework',A)
