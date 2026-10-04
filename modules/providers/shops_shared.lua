local P=DT.Providers
local shops,sessions,busy={},{},{}
local function permitted(src,shop)
    if shop.groups and not DT.Player.HasGroup(src,shop.groups) then return false end
    if not shop.coords then return true end
    local pos=DT.Player.GetCoords(src);if not pos then return false end
    local locations=shop.coords.x and {shop.coords} or shop.coords
    for _,point in pairs(locations) do
        local dx,dy,dz=pos.x-point.x,pos.y-point.y,pos.z-point.z
        if dx*dx+dy*dy+dz*dz<=25 then return true end
    end
    return false
end
P.Register('shops','native',function()
    local api={}
    if P.Server then
        function api.CreateShop(name,items,coords,groups)
            if type(name)~='string' or name=='' or type(items)~='table' then return false,'invalid_shop' end
            shops[name]={items=DTUtils.copy(items),coords=coords,groups=groups};return true
        end
        function api.OpenShop(src,name)
            local shop=shops[name];if not shop or not permitted(src,shop) then return false,'access_denied' end
            sessions[src]={name=name,expires=GetGameTimer()+300000}
            TriggerClientEvent('DTlib:provider:shopOpen',src,name,shop.items);return true
        end
        function api.CompleteCheckout(src,name,item,count,account)
            local shop=shops[name];local session=sessions[src];count=tonumber(count)
            if not shop or not session or session.name~=name or session.expires<GetGameTimer() or not permitted(src,shop) then return false,'access_denied' end
            if not count or count<1 or count>100 or count%1~=0 then return false,'invalid_count' end
            if account~='cash' and account~='bank' and account~='money' then return false,'invalid_account' end
            account=account=='money' and 'cash' or account
            local listing;for _,entry in ipairs(shop.items) do if entry.name==item then listing=entry;break end end
            local price=listing and tonumber(listing.price)
            if not price or price<0 or price~=price or price==math.huge or price*count==math.huge then return false,'invalid_item' end
            if listing.count and listing.count<count then return false,'insufficient_stock' end
            if busy[name] then return false,'busy' end
            busy[name]=true
            local paid=false;local total=price*count
            local ok,result,reason=pcall(function()
                if not DT.Inventory.CanCarry(src,item,count) then return false,'inventory_full' end
                if DT.Player.GetMoney(src,account)<total then return false,'insufficient_funds' end
                if total>0 then if not DT.Player.RemoveMoney(src,account,total,'DTlib shop '..name) then return false,'payment_failed' end;paid=true end
                local added=DT.Inventory.AddItem(src,item,count,listing.metadata)
                if not added then return false,'inventory_failed' end
                paid=false;if listing.count then listing.count=listing.count-count end;return true
            end)
            busy[name]=nil
            if paid then
                local refunded,value=pcall(DT.Player.AddMoney,src,account,total,'DTlib shop refund '..name)
                if not refunded or not value then print(('DTlib: refund requires attention (player %s, shop %s, amount %s)'):format(src,name,total)) end
            end
            if not ok then return false,'checkout_failed' end
            return result,reason
        end
        api.FinalizeCheckOut=api.CompleteCheckout
    else
        function api.AmountSelect(item)
            local result=DT.Input.Await({title=item.label or item.name,fields={{name='amount',type='number',label='Quantity',min=1,max=100,required=true,default=1}}})
            return result and tonumber(result.amount)
        end
        function api.OpenShop(name) return DT.Callback.Await('DTlib:provider:shopRequest',name) end
        function api.CompleteCheckout(name,item,count,account) return DT.Callback.Await('DTlib:provider:shopCheckout',name,item,count,account or 'cash') end
        api.FinalizeCheckOut=api.CompleteCheckout
    end
    return api
end)
if P.Server then
    DT.Callback.Register('DTlib:provider:shopRequest',function(src,name) return DT.Ecosystem.Shops.OpenShop(src,name) end)
    DT.Callback.Register('DTlib:provider:shopCheckout',function(src,...) return DT.Ecosystem.Shops.CompleteCheckout(src,...) end)
    AddEventHandler('playerDropped',function() sessions[source]=nil end)
else
    RegisterNetEvent('DTlib:provider:shopOpen',function(name,items)
        if source~=65535 then return end
        local rows={}
        for _,item in ipairs(items) do
            rows[#rows+1]={title=item.label or item.name,description=('$%s'):format(item.price),onSelect=function()
                local api=DT.Ecosystem.Get('shops','native');local count=api.AmountSelect(item);if not count then return end
                local ok,reason=api.CompleteCheckout(name,item.name,count,'cash')
                DT.Notify({title=name,message=ok and 'Purchase complete' or ('Purchase failed: '..tostring(reason)),type=ok and 'success' or 'error'})
            end}
        end
        DT.Menu.Open({title=name,items=rows})
    end)
end
