local A={resource='framework',publicName='framework'}
function A:available() return true end
function A:getItems() local d=DT.Player.GetData and DT.Player.GetData() or {}; return d.items or {} end
function A:getItemData(i)
    if DTUtils.isStarted('qb-core') then local ok,c=pcall(function() return exports['qb-core']:GetCoreObject() end); if ok and c and c.Shared and c.Shared.Items then return c.Shared.Items[i] end end
end
DT.Modules.Register('inventory','framework',A)
