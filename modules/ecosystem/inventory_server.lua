local function call(provider,method,...)
    local a,err=DT.Ecosystem.Get('inventory',provider)
    if not a then return nil,err end
    if not DTUtils.isCallable(a[method]) then return nil,'unsupported_backend' end
    return a[method](...)
end
for _,p in ipairs(DTEcosystemCatalog.inventory.providers) do
    if not p.default and not DT.Modules.Get('inventory',p.resource) then
        local name=p.name
        local A={resource=p.resource,publicName=p.resource}
        function A:available() return DTConfig.Ecosystem.enabled~=false and DTUtils.isStarted(self.resource) end
        function A:addItem(src,item,count,metadata,slot) return call(name,'AddItem',src,item,count,slot,metadata) end
        function A:removeItem(src,item,count,metadata,slot) return call(name,'RemoveItem',src,item,count,slot,metadata) end
        function A:getCount(...) return call(name,'GetItemCount',...) end
        function A:canCarry(...) local r,e=call(name,'CanCarryItem',...);return r==true,e end
        function A:getItems(...) return call(name,'GetPlayerInventory',...) end
        function A:getSlot(...) return call(name,'GetItemBySlot',...) end
        function A:getItemData(...) return call(name,'GetItemInfo',...) end
        function A:items(item) local items=call(name,'Items');return item and items and items[item] or items end
        function A:registerStash(...) return call(name,'RegisterStash',...) end
        function A:forceOpen(src,kind,id) return call(name,'OpenStash',src,kind,type(id)=='table' and id.id or id) end
        function A:setMetadata(src,slot,metadata)
            local item=call(name,'GetItemBySlot',src,slot)
            if not item then return false,'invalid_slot' end
            return call(name,'SetMetadata',src,item.name,slot,metadata)
        end
        function A:updateVehicle(oldPlate,newPlate) return call(name,'UpdatePlate',oldPlate,newPlate) end
        DT.Modules.Register('inventory',p.resource,A)
    end
end
