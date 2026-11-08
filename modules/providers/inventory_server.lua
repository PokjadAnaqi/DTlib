local providerRegistry = DT.Providers
local schemas = {
    ['qs-inventory'] = { 'inventory_trunk', 'inventory_glovebox' },
    ['jpr-inventory'] = { 'trunkitems', 'gloveboxitems' },
    ['ps-inventory'] = { 'trunkitems', 'gloveboxitems' },
    origen_inventory = { 'trunkitems', 'gloveboxitems' },
}
function providerRegistry.InventoryExtras(api, resource)
    if schemas[resource] then
        api.UpdatePlate = function(old, new)
            if type(old) ~= 'string' or type(new) ~= 'string' or new == '' or #new > 16 then
                return false, 'invalid_plate'
            end
            local queries = {}
            for _, name in ipairs(schemas[resource]) do
                queries[#queries + 1] =
                    { query = 'UPDATE ' .. name .. ' SET plate = ? WHERE plate = ?', values = { new, old } }
            end
            local ok = DT.Database.Transaction(queries)
            if ok and GetResourceState('jg-mechanic') == 'started' then
                providerRegistry.Export('jg-mechanic', 'vehiclePlateUpdated', old, new)
            end
            return ok
        end
    elseif resource == 'core_inventory' then
        api.UpdatePlate = function(old, new)
            if type(old) ~= 'string' or type(new) ~= 'string' or new == '' or #new > 16 then
                return false, 'invalid_plate'
            end
            local queries = {}
            for _, prefix in ipairs({ '', 'glovebox-', 'trunk-' }) do
                queries[#queries + 1] = {
                    query = 'UPDATE coreinventories SET name = ? WHERE name = ?',
                    values = { prefix .. new, prefix .. old },
                }
            end
            return DT.Database.Transaction(queries)
        end
    elseif resource == 'qb-inventory' then
        api.UpdatePlate = function(old, new)
            if type(old) ~= 'string' or type(new) ~= 'string' or new == '' or #new > 16 then
                return false, 'invalid_plate'
            end
            local previous = {}
            for _, prefix in ipairs({ 'glovebox-', 'trunk-' }) do
                local existing = providerRegistry.Export(resource, 'GetInventory', prefix .. old)
                if existing then
                    if providerRegistry.Export(resource, 'GetInventory', prefix .. new) then
                        return false, 'destination_exists'
                    end
                    previous[#previous + 1] = { old = prefix .. old, new = prefix .. new, data = existing }
                end
            end
            local queries = {}
            for _, entry in ipairs(previous) do
                queries[#queries + 1] = {
                    query = 'UPDATE inventories SET identifier = ? WHERE identifier = ?',
                    values = { entry.new, entry.old },
                }
            end
            if #queries > 0 and not DT.Database.Transaction(queries) then
                return false, 'plate_update_failed'
            end
            for _, entry in ipairs(previous) do
                providerRegistry.Export(
                    resource,
                    'CreateInventory',
                    entry.new,
                    { label = entry.data.label, slots = entry.data.slots, maxweight = entry.data.maxweight }
                )
                providerRegistry.Export(resource, 'SetInventory', entry.new, entry.data.items)
                providerRegistry.Export(resource, 'ClearStash', entry.old)
            end
            return true
        end
    end
end
