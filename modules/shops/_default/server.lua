-- DTlib-native implementation of the community Shops contract.
Shops={}
local registered,opened,locked={},{},{}
local function allowed(src,shop)
    if not src or not GetPlayerName(src) then return false end
    if shop.groups and not DT.Player.HasGroup(src,shop.groups) then return false end
    if shop.shopCoords then
        local pos=DT.Player.GetCoords(src);if not pos then return false end
        local coords=shop.shopCoords
        local points=(coords.x~=nil) and {coords} or coords
        local near=false
        for _,c in pairs(points) do
            if c and c.x and c.y and c.z then
                local dx,dy,dz=pos.x-c.x,pos.y-c.y,pos.z-c.z
                if dx*dx+dy*dy+dz*dz<=25 then near=true;break end
            end
        end
        if not near then return false end
    end
    return true
end
function Shops.GetResourceName() return 'native' end
function Shops.CreateShop(name,inventory,coords,groups)
    if type(name)~='string' or name=='' or type(inventory)~='table' then return false,'invalid_shop' end
    if registered[name] then return true end
    registered[name]={name=name,inventory=DTUtils.copy(inventory),shopCoords=coords,groups=groups}
    return true
end
function Shops.OpenShop(src,name)
    local shop=registered[name]
    if not shop or not allowed(src,shop) then return false,'access_denied' end
    opened[src]=opened[src] or {};opened[src][name]=GetGameTimer()
    TriggerClientEvent('DTlib:ecosystem:Client:openShop',src,'shop',name,shop)
    return true
end
function Shops.CompleteCheckout(src,name,item,amount,account)
    local shop=registered[name];amount=tonumber(amount)
    if not shop or not allowed(src,shop) then return false,'access_denied' end
    local session=opened[src] and opened[src][name]
    if not session or GetGameTimer()-session>300000 then return false,'shop_not_open' end
    if account~='money' and account~='cash' and account~='bank' then return false,'invalid_account' end
    if not amount or amount~=amount or amount%1~=0 or amount<1 or amount>100 then return false,'invalid_amount' end
    local data
    for _,v in pairs(shop.inventory) do if v.name==item then data=v;break end end
    local price=data and tonumber(data.price)
    if not price or price~=price or price<0 or price==math.huge then return false,'invalid_item' end
    if data.count and (tonumber(data.count) or 0)<amount then return false,'not_enough_stock' end
    if locked[name] then return false,'busy' end
    local total=price*amount;if total==math.huge then return false,'invalid_price' end
    account=account=='money' and 'cash' or account
    if not DT.Inventory.CanCarry(src,item,amount) then return false,'inventory_full' end
    if DT.Player.GetMoney(src,account)<total then return false,'not_enough_money' end
    locked[name]=true
    local debited=false
    local ok,result,reason=pcall(function()
        if total>0 then
            if not DT.Player.RemoveMoney(src,account,total,'dtlib-shop:'..name) then return false,'payment_failed' end
            debited=true
        end
        local added=DT.Inventory.AddItem(src,item,amount)
        if not added then return false,'inventory_failed' end
        debited=false
        if data.count then data.count=data.count-amount end
        return true
    end)
    if debited then DT.Player.AddMoney(src,account,total,'dtlib-shop-refund:'..name) end
    locked[name]=nil
    if not ok then return false,'checkout_failed' end
    return result,reason
end
RegisterNetEvent('DTlib:ecosystem:Server:completeCheckout',function(name,item,amount,account)
    local src=source
    local success,reason=Shops.CompleteCheckout(src,name,item,amount,account)
    DT.Notify(src,{title='SHOP',message=success and 'Purchase complete.' or ('Purchase failed: '..tostring(reason)),type=success and 'success' or 'error'})
end)
AddEventHandler('playerDropped',function() opened[source]=nil end)
return Shops
