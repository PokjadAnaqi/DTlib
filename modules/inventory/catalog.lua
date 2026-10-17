-- Shared definitions, never a player's inventory or an authority for grants.
local imageFolders={ox_inventory='web/images/',one_inventory='web/images/',core_inventory='html/img/',['codem-inventory']='html/itemimages/',['tgiann-inventory']='images/'}
function DT.Inventory.GetItemImage(item,definition)
    local data=definition or DT.Inventory.GetItemData(item)
    if type(data)~='table' then return nil,'item_not_found' end
    local image=data.image or (type(data.client)=='table' and data.client.image)
    if type(image)=='string' and (image:match('^https://') or image:match('^nui://')) then return image end
    if type(image)=='string' and image:find(':',1,true) then return nil,'invalid_image' end
    local provider=DT.Inventory.Name()
    if provider=='framework' then
        if DTUtils.isStarted('qb-inventory') then provider='qb-inventory' else return nil,'image_path_unavailable' end
    end
    local resource=provider=='tgiann-inventory' and 'inventory_images' or provider
    image=type(image)=='string' and image~='' and image or tostring(item)..'.png'
    if image:find('..',1,true) or image:sub(1,1)=='/' or image:find('\\',1,true) then return nil,'invalid_image' end
    return ('nui://%s/%s%s'):format(resource,imageFolders[provider] or 'html/images/',image)
end

function DT.Inventory.GetCatalog(options)
    options=type(options)=='table' and options or {}
    local ok,definitions,err=pcall(DT.Inventory.Items)
    if not ok then return nil,'provider_not_ready' end
    if type(definitions)~='table' then return nil,err or 'catalog_unavailable' end
    if type(definitions.items)=='table' and not definitions.items.name and not definitions.items.label then definitions=definitions.items end
    local result={}
    for key,value in pairs(definitions) do
        if type(value)=='table' then
            local name=value.name or value.item or (type(key)=='string' and key)
            if type(name)=='string' and name~='' then
                local entry=DTUtils.copy(value)
                entry.name=name
                entry.label=tostring(value.label or value.displayName or name)
                entry.description=tostring(value.description or '')
                entry.weight=tonumber(value.weight) or 0
                entry.image=DT.Inventory.GetItemImage(name,value)
                entry.rarity=value.rarity or (type(value.metadata)=='table' and value.metadata.rarity) or nil
                result[name]=entry
            end
        end
    end
    if options.asArray then
        local array={};for _,entry in pairs(result) do array[#array+1]=entry end
        table.sort(array,function(a,b) return a.name<b.name end)
        return array
    end
    return result
end
