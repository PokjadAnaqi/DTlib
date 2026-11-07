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
function DT.Inventory.SetGetPlayerNameMethod(callback)
    if not DTUtils.isCallable(callback) then
        return false, 'callback_required'
    end
    return call('setGetPlayerNameMethod', callback)
end
function DT.Inventory.Open(inventoryType, details)
    return call('open', inventoryType, details)
end
function DT.Inventory.OpenStash(id, owner)
    return DT.Inventory.Open('stash', owner ~= nil and { id = id, owner = owner } or id)
end
function DT.Inventory.UseItem(details, callback)
    return call('useItem', details, callback)
end
function DT.Inventory.UseSlot(sourceId)
    return call('useSlot', sourceId)
end
function DT.Inventory.SetStashTarget(id, owner)
    return call('setStashTarget', id, owner)
end
function DT.Inventory.GetCurrentWeapon()
    return call('getCurrentWeapon')
end
function DT.Inventory.DisplayMetadata(methodName, result)
    return call('displayMetadata', methodName, result)
end
function DT.Inventory.GiveItemToTarget(sourceId, slot, coreObject)
    return call('giveItemToTarget', sourceId, slot, coreObject)
end
function DT.Inventory.WeaponWheel(state)
    return call('weaponWheel', state)
end
function DT.Inventory.Search(sourceId, index, methodName)
    return call('search', sourceId, index, methodName)
end
function DT.Inventory.GetCount(index, methodName, strict)
    return tonumber(call('getCount', index, methodName, strict) or 0) or 0
end
DT.Inventory.GetItemCount = DT.Inventory.GetCount
function DT.Inventory.HasItem(index, coreObject, methodName, strict)
    return DT.Inventory.GetCount(index, methodName, strict) >= (tonumber(coreObject) or 1)
end
function DT.Inventory.GetItems()
    return call('getItems') or {}
end
DT.Inventory.GetPlayerItems = DT.Inventory.GetItems
function DT.Inventory.GetWeight()
    return tonumber(call('getWeight') or 0) or 0
end
function DT.Inventory.GetMaxWeight()
    return tonumber(call('getMaxWeight') or 0) or 0
end
function DT.Inventory.GetSlotIdWithItem(...)
    return call('getSlotIdWithItem', ...)
end
function DT.Inventory.GetSlotIdsWithItem(...)
    return call('getSlotIdsWithItem', ...)
end
function DT.Inventory.GetSlotWithItem(...)
    return call('getSlotWithItem', ...)
end
function DT.Inventory.GetSlotsWithItem(...)
    return call('getSlotsWithItem', ...)
end
function DT.Inventory.SuppressItemNotifications(state)
    return call('suppressItemNotifications', state)
end
function DT.Inventory.IsBusy()
    return LocalPlayer and LocalPlayer.state and LocalPlayer.state.invBusy == true or false
end
function DT.Inventory.SetBusy(state, rep)
    if not LocalPlayer or not LocalPlayer.state then
        return false
    end
    LocalPlayer.state:set('invBusy', state == true, rep == true)
    return true
end
function DT.Inventory.IsOpen()
    return LocalPlayer and LocalPlayer.state and LocalPlayer.state.invOpen == true or false
end
function DT.Inventory.SetHotkeys(state, rep)
    if not LocalPlayer or not LocalPlayer.state then
        return false
    end
    LocalPlayer.state:set('invHotkeys', state ~= false, rep == true)
    return true
end
function DT.Inventory.HotkeysEnabled()
    return not LocalPlayer or not LocalPlayer.state or LocalPlayer.state.invHotkeys ~= false
end
function DT.Inventory.SetCanUseWeapons(state, rep)
    if not LocalPlayer or not LocalPlayer.state then
        return false
    end
    LocalPlayer.state:set('canUseWeapons', state ~= false, rep == true)
    return true
end
function DT.Inventory.CanUseWeapons()
    return not LocalPlayer or not LocalPlayer.state or LocalPlayer.state.canUseWeapons ~= false
end
function DT.Inventory.SetInstance(instance, rep)
    if not LocalPlayer or not LocalPlayer.state then
        return false
    end
    LocalPlayer.state:set('instance', instance, rep ~= false)
    return true
end
function DT.Inventory.GetInstance()
    return LocalPlayer and LocalPlayer.state and LocalPlayer.state.instance or nil
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

AddEventHandler('onClientResourceStart', function()
    DT.Inventory.ClearItemCache()
end)
AddEventHandler('onClientResourceStop', function()
    DT.Inventory.ClearItemCache()
end)
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
