local aliases = { ox = 'ox_inventory', dtgrid = 'ox_inventory', qb = 'qb-inventory' }
local function resolveAdapter()
    local candidates = { 'ox_inventory', 'qb-inventory' }
    for _, provider in ipairs(DTEcosystemCatalog.inventory.providers) do
        if not provider.default and not DTUtils.tableContains(candidates, provider.resource) then
            candidates[#candidates + 1] = provider.resource
        end
    end
    return DT.Modules.Resolve('inventory', DTConfig.Adapters.inventory, candidates, aliases, 'framework')
end
local function call(methodName, ...)
    local provider = resolveAdapter()
    if not provider or type(provider[methodName]) ~= 'function' then
        return nil, 'unsupported_backend'
    end
    return provider[methodName](provider, ...)
end
local itemCache = {}
local cacheProvider, cacheFramework
local function currentProvider()
    local adapter = resolveAdapter()
    local framework = DT.Framework.Name and DT.Framework.Name() or ''
    if cacheProvider ~= adapter or cacheFramework ~= framework then
        itemCache = {}
        cacheProvider = adapter
        cacheFramework = framework
    end
    return adapter
end
function DT.Inventory.Supports(method)
    if type(method) ~= 'string' or method == '' then
        return false
    end
    local aliases = { CanCarryItem = 'canCarry', GetItemCount = 'getCount', GetInventoryItems = 'getItems' }
    local key = aliases[method] or method:sub(1, 1):lower() .. method:sub(2)
    local provider = currentProvider()
    if provider and provider.supports then
        return provider:supports(key) == true
    end
    return provider ~= nil and type(provider[key]) == 'function'
end
function DT.Inventory.Name()
    local provider = resolveAdapter()
    return provider and provider.publicName or 'framework'
end
function DT.Inventory.Available()
    local provider = resolveAdapter()
    return provider and provider.resource ~= 'framework'
end
function DT.Inventory.SetPlayerInventory(...)
    return call('setPlayerInventory', ...)
end
function DT.Inventory.Items(item)
    local value, errorMessage = call('items', item)
    if value ~= nil then
        return value
    end
    if item then
        return DT.Inventory.GetItemData(item)
    end
    return nil, errorMessage or 'catalog_unavailable'
end
local function validCount(count)
    count = count == nil and 1 or tonumber(count)
    if not count or count ~= count or count == math.huge or count <= 0 or count % 1 ~= 0 then
        return nil
    end
    return count
end
function DT.Inventory.CanCarry(inventory, item, count, metadata)
    count = validCount(count)
    if not count then
        return false, 'invalid_count'
    end
    return call('canCarry', inventory, item, count, metadata)
end
DT.Inventory.CanCarryItem = DT.Inventory.CanCarry
function DT.Inventory.CanCarryAmount(...)
    return call('canCarryAmount', ...)
end
function DT.Inventory.CanCarryWeight(...)
    local result, remainingWeight = call('canCarryWeight', ...)
    return result or false, remainingWeight or 0
end
function DT.Inventory.CanSwapItem(...)
    return call('canSwapItem', ...)
end
function DT.Inventory.AddItem(inventory, item, count, metadata, slot, reason)
    count = validCount(count)
    if not count then
        return false, 'invalid_count'
    end
    local carry, errorMessage = DT.Inventory.CanCarry(inventory, item, count, metadata)
    if carry == false then
        return false, errorMessage or 'inventory_full'
    end
    if carry == nil and errorMessage and errorMessage ~= 'unsupported_backend' then
        return false, errorMessage
    end
    -- Providers without preflight must enforce capacity in their authoritative AddItem.
    return call('addItem', inventory, item, count, metadata, slot, reason)
end
function DT.Inventory.RemoveItem(inventory, item, count, metadata, slot, reason, ignore, strict)
    count = validCount(count)
    if not count then
        return false, 'invalid_count'
    end
    return call('removeItem', inventory, item, count, metadata, slot, reason, ignore, strict)
end
function DT.Inventory.GetItem(inventory, item, metadata, returnsCount)
    local result = call('getItem', inventory, item, metadata, returnsCount)
    if result ~= nil then
        return result
    end
    if returnsCount then
        return DT.Inventory.GetCount(inventory, item, metadata)
    end
    local details = DT.Inventory.GetItemData(type(item) == 'string' and item or nil)
    if not details then
        return nil
    end
    details = DTUtils.copy(details)
    details.count = DT.Inventory.GetCount(inventory, item, metadata)
    return details
end
function DT.Inventory.GetCount(inventory, item, metadata, strict)
    return tonumber(call('getCount', inventory, item, metadata, strict) or 0) or 0
end
DT.Inventory.GetItemCount = DT.Inventory.GetCount
function DT.Inventory.HasItem(inventory, item, count, metadata, strict)
    return DT.Inventory.GetCount(inventory, item, metadata, strict) >= (tonumber(count) or 1)
end
function DT.Inventory.Search(inventory, sourceId, item, metadata)
    local result = call('search', inventory, sourceId, item, metadata)
    if result ~= nil then
        return result
    end
    if sourceId == 'count' then
        return DT.Inventory.GetCount(inventory, item, metadata)
    end
end
for _, methodName in ipairs({
    'GetItemSlots',
    'GetSlot',
    'GetSlotForItem',
    'GetSlotIdWithItem',
    'GetSlotIdsWithItem',
    'GetSlotWithItem',
    'GetSlotsWithItem',
    'GetEmptySlot',
    'GetContainerFromSlot',
    'GetInventory',
    'GetInventories',
}) do
    local key = methodName:sub(1, 1):lower() .. methodName:sub(2)
    DT.Inventory[methodName] = function(...)
        return call(key, ...)
    end
end
function DT.Inventory.GetItems(inventory, owner)
    return call('getItems', inventory, owner) or {}
end
DT.Inventory.GetInventoryItems = DT.Inventory.GetItems
function DT.Inventory.SetMaxWeight(inventory, width)
    return call('setMaxWeight', inventory, tonumber(width) or 0)
end
function DT.Inventory.SetSlotCount(inventory, sourceId)
    return call('setSlotCount', inventory, tonumber(sourceId) or 0)
end
function DT.Inventory.SetMetadata(inventory, sourceId, methodName)
    return call('setMetadata', inventory, sourceId, methodName or {})
end
function DT.Inventory.SetDurability(inventory, sourceId, details)
    return call('setDurability', inventory, sourceId, tonumber(details) or 0)
end
function DT.Inventory.GetCurrentWeapon(inventory)
    return call('getCurrentWeapon', inventory)
end
function DT.Inventory.RegisterStash(id, label, slots, maxWeight, owner, groups, coords, instance)
    if type(id) == 'table' then
        local details = id
        id = details.id
        label = details.label
        slots = details.slots
        maxWeight = details.maxWeight or details.maxweight
        owner = details.owner
        groups = details.groups
        coords = details.coords
        instance = details.instance
    end
    return call('registerStash', id, label, slots, maxWeight, owner, groups, coords, instance)
end
function DT.Inventory.CreateTemporaryStash(...)
    return call('createTemporaryStash', ...)
end
function DT.Inventory.CustomDrop(...)
    return call('customDrop', ...)
end
function DT.Inventory.CreateDropFromPlayer(...)
    return call('createDropFromPlayer', ...)
end
function DT.Inventory.SetContainerProperties(...)
    return call('setContainerProperties', ...)
end
function DT.Inventory.Clear(...)
    return call('clear', ...)
end
DT.Inventory.ClearInventory = DT.Inventory.Clear
function DT.Inventory.RemoveInventory(...)
    return call('removeInventory', ...)
end
function DT.Inventory.ForceOpen(...)
    return call('forceOpen', ...)
end
function DT.Inventory.OpenStash(source, id, owner)
    return DT.Inventory.ForceOpen(source, 'stash', owner ~= nil and { id = id, owner = owner } or id)
end
function DT.Inventory.UpdateVehicle(...)
    return call('updateVehicle', ...)
end
function DT.Inventory.Inspect(...)
    return call('inspect', ...)
end
function DT.Inventory.Confiscate(...)
    return call('confiscate', ...)
end
function DT.Inventory.Return(...)
    return call('returnInventory', ...)
end
function DT.Inventory.ConvertItems(...)
    return call('convertItems', ...)
end
function DT.Inventory.GetItemData(item)
    if type(item) ~= 'string' or item == '' then
        return nil, 'invalid_item'
    end
    local provider = currentProvider()
    local cached = itemCache[item]
    if cached and GetGameTimer() - cached.at < 60000 and GetGameTimer() >= cached.at then
        return DTUtils.copy(cached.data)
    end
    if not provider or type(provider.getItemData) ~= 'function' then
        return nil, 'unsupported_backend'
    end
    local ok, data = pcall(provider.getItemData, provider, item)
    if not ok then
        return nil, 'provider_not_ready'
    end
    -- Never cache misses: an inventory may still be loading its definitions.
    if type(data) ~= 'table' then
        return nil, 'item_not_found'
    end
    data = DTUtils.copy(data)
    data.name = data.name or item
    itemCache[item] = { data = data, at = GetGameTimer() }
    return DTUtils.copy(data)
end
function DT.Inventory.GetItemLabel(item)
    local details = DT.Inventory.GetItemData(item)
    local list = details and (details.label or details.displayName or details.name)
    return list and tostring(list) or nil
end
function DT.Inventory.ClearItemCache(item)
    if type(item) == 'string' and item ~= '' then
        itemCache[item] = nil
    else
        itemCache = {}
    end
    return true
end

AddEventHandler('onResourceStart', function()
    DT.Inventory.ClearItemCache()
end)
AddEventHandler('onResourceStop', function()
    DT.Inventory.ClearItemCache()
end)
function DT.Inventory.RegisterUsableItem(name, callback)
    if type(name) ~= 'string' or name == '' or not DTUtils.isCallable(callback) then
        return false, 'invalid_usable_item'
    end
    return DT.Ecosystem.Call('framework', 'RegisterUsableItem', name, callback)
end
