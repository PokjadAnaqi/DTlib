local function call(provider, method, ...)
    local adapter, errorMessage = DT.Ecosystem.Get('inventory', provider)
    if not adapter then
        return nil, errorMessage
    end
    if not DTUtils.isCallable(adapter[method]) then
        return nil, 'unsupported_backend'
    end
    return adapter[method](...)
end
for _, adapter in ipairs(DTEcosystemCatalog.inventory.providers) do
    if not adapter.default and not DT.Modules.Get('inventory', adapter.resource) then
        local name = adapter.name
        local providerAdapter = { resource = adapter.resource, publicName = adapter.resource }
        function providerAdapter:supports(method)
            local names = {
                items = 'Items',
                getItemData = 'GetItemInfo',
                getCount = 'GetItemCount',
                getItems = 'GetPlayerInventory',
                getSlot = 'GetItemBySlot',
                canCarry = 'CanCarryItem',
                addItem = 'AddItem',
                removeItem = 'RemoveItem',
                setMetadata = 'SetMetadata',
                registerStash = 'RegisterStash',
                forceOpen = 'OpenStash',
                updateVehicle = 'UpdatePlate',
            }
            return names[method] ~= nil and DT.Ecosystem.Supports('inventory', names[method], name)
        end
        function providerAdapter:available()
            return DTConfig.Ecosystem.enabled ~= false and DTUtils.isStarted(self.resource)
        end
        function providerAdapter:addItem(playerSource, item, count, metadata, slot)
            return call(name, 'AddItem', playerSource, item, count, slot, metadata)
        end
        function providerAdapter:removeItem(playerSource, item, count, metadata, slot)
            return call(name, 'RemoveItem', playerSource, item, count, slot, metadata)
        end
        function providerAdapter:getCount(...)
            return call(name, 'GetItemCount', ...)
        end
        function providerAdapter:canCarry(...)
            return call(name, 'CanCarryItem', ...)
        end
        function providerAdapter:getItems(...)
            return call(name, 'GetPlayerInventory', ...)
        end
        function providerAdapter:getSlot(...)
            return call(name, 'GetItemBySlot', ...)
        end
        function providerAdapter:getItemData(...)
            return call(name, 'GetItemInfo', ...)
        end
        function providerAdapter:items(item)
            local items, errorMessage = call(name, 'Items')
            if type(items) ~= 'table' then
                return nil, errorMessage
            end
            if item then
                return items[item]
            end
            return items
        end
        function providerAdapter:registerStash(...)
            return call(name, 'RegisterStash', ...)
        end
        function providerAdapter:forceOpen(playerSource, kind, id)
            return call(name, 'OpenStash', playerSource, kind, type(id) == 'table' and id.id or id)
        end
        function providerAdapter:setMetadata(playerSource, slot, metadata)
            local item = call(name, 'GetItemBySlot', playerSource, slot)
            if not item then
                return false, 'invalid_slot'
            end
            return call(name, 'SetMetadata', playerSource, item.name, slot, metadata)
        end
        function providerAdapter:updateVehicle(oldPlate, newPlate)
            return call(name, 'UpdatePlate', oldPlate, newPlate)
        end
        DT.Modules.Register('inventory', adapter.resource, providerAdapter)
    end
end
