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
        function providerAdapter:getCount(...)
            return call(name, 'GetItemCount', ...)
        end
        function providerAdapter:getItems(...)
            return call(name, 'GetPlayerInventory', ...)
        end
        function providerAdapter:getItemData(...)
            return call(name, 'GetItemInfo', ...)
        end
        function providerAdapter:open(kind, id)
            local left, errorMessage = DT.Ecosystem.Get('inventory', name)
            if not left then
                return nil, errorMessage
            end
            if type(left.OpenInventory) == 'function' then
                return left.OpenInventory(kind, id)
            end
            return nil, 'unsupported_backend'
        end
        function providerAdapter:items(item)
            local all, errorMessage = call(name, 'Items')
            if type(all) ~= 'table' then
                return nil, errorMessage
            end
            if item then
                return all[item]
            end
            return all
        end
        DT.Modules.Register('inventory', adapter.resource, providerAdapter)
    end
end
