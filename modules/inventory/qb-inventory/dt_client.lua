local A={resource='qb-inventory',publicName='qb-inventory'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:open(t,d) local ok,v=pcall(function() return exports['qb-inventory']:OpenInventory(t,d) end); return ok and v or false end
function A:getItems() local d=DT.Player.GetData and DT.Player.GetData() or {}; return d.items or {} end
function A:items(item) return DT.Modules.Get('inventory','framework'):items(item) end
function A:getItemData(item) return self:items(item) end
DT.Modules.Register('inventory','qb-inventory',A)
