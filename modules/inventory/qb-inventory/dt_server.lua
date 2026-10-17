local A={resource='qb-inventory',publicName='qb-inventory'}
local function ex(name,...)
    local args={...}; local ok,a,b,c=pcall(function() local fn=exports['qb-inventory'][name]; if not fn then return nil end; return fn(exports['qb-inventory'],table.unpack(args)) end); if not ok then return nil,a end; return a,b,c
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:canCarry(inv,item,count)
    local value,reason=ex('CanAddItem',inv,item,count)
    if value==nil then return nil,'provider_not_ready' end
    return value==true,reason
end
function A:addItem(inv,item,count,metadata,slot,reason) local a,b=ex('AddItem',inv,item,count,slot,metadata,reason or 'DTlib'); return a==true,b end
function A:removeItem(inv,item,count,metadata,slot,reason) local a,b=ex('RemoveItem',inv,item,count,slot,reason or 'DTlib'); return a==true,b end
function A:getCount(inv,item) local v=ex('GetItemByName',inv,item); return v and (v.amount or v.count or 0) or 0 end
function A:getSlot(inv,slot) return ex('GetItemBySlot',inv,slot) end
function A:getItems(inv) local p=type(inv)=='number' and DT.Player.Get(inv) or nil; return p and p.PlayerData and p.PlayerData.items or {} end
function A:registerStash(id,label,slots,maxWeight) local v=ex('CreateInventory',id,{label=label,maxweight=maxWeight,slots=slots}); return v~=nil end
function A:clear(inv,keep) local v=ex('ClearInventory',inv,keep); return v~=nil end
function A:forceOpen(playerId,invType,data) if invType~='stash' then return false end; local v=ex('OpenInventory',playerId,type(data)=='table' and data.id or data); return v~=nil end
function A:items(item) return DT.Modules.Get('inventory','framework'):items(item) end
function A:getItemData(item) return self:items(item) end
DT.Modules.Register('inventory','qb-inventory',A)
