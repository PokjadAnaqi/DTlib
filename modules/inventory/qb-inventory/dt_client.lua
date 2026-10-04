local A={resource='qb-inventory',publicName='qb-inventory'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:open(t,d) local ok,v=pcall(function() return exports['qb-inventory']:OpenInventory(t,d) end); return ok and v or false end
function A:getItems() local d=DT.Player.GetData and DT.Player.GetData() or {}; return d.items or {} end
function A:getItemData(i)
    if not DTUtils.isStarted('qb-core') then return nil end
    local ok,c=pcall(function() return exports['qb-core']:GetCoreObject() end)
    return ok and c and c.Shared and c.Shared.Items and c.Shared.Items[i] or nil
end
DT.Modules.Register('inventory','qb-inventory',A)
