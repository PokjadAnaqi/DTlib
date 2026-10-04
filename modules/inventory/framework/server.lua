local A={resource='framework',publicName='framework'}
function A:available() return true end
function A:addItem(inv,item,count,metadata,slot) local p=type(inv)=='number' and DT.Player.Get(inv) or nil; return p and p.Functions and p.Functions.AddItem and p.Functions.AddItem(item,count,slot,metadata) or false,'no_inventory_backend' end
function A:removeItem(inv,item,count,metadata,slot) local p=type(inv)=='number' and DT.Player.Get(inv) or nil; return p and p.Functions and p.Functions.RemoveItem and p.Functions.RemoveItem(item,count,slot) or false,'no_inventory_backend' end
function A:getCount(inv,item) local p=type(inv)=='number' and DT.Player.Get(inv) or nil; local n=0; for _,e in pairs(p and p.PlayerData and p.PlayerData.items or {}) do if e and e.name==item then n=n+(e.amount or e.count or 0) end end; return n end
function A:getItems(inv) local p=type(inv)=='number' and DT.Player.Get(inv) or nil; return p and p.PlayerData and p.PlayerData.items or {} end
function A:getItemData(item)
    if DT.Framework.Name and DT.Framework.Name()=='qb' and DTUtils.isStarted('qb-core') then local ok,c=pcall(function() return exports['qb-core']:GetCoreObject() end); return ok and c and c.Shared and c.Shared.Items and c.Shared.Items[item] or nil end
end
DT.Modules.Register('inventory','framework',A)
