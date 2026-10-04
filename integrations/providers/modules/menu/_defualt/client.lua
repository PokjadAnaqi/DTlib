Menus = Menus or {}
Menu = {}

---Opens a menu based on the configuration.
---@param data table The menu data.
---@param useQb boolean Whether to use QB menu syntax.
---@return id string The menu ID.
function Menu.Open(data, useQb)
    local id = data.id or Ids.CreateUniqueId(Menus, nil, nil)
    Menus[id] = data
    OpenMenu(id, data, useQb)
    data.id = id
    return id
end

function Menu.GetResourceName()
    return GetMenuResourceName()
end

---Event to handle callback from menu selection.
---@param _args table The arguments passed to the callback.
---@return nil
RegisterNetEvent('DTlib:ecosystem:client:MenuCallback', function(data)
    if type(data)~='table' then return end
    local menu=Menus[data.id]
    local selected=tonumber(data.selected)
    local item=menu and selected and menu.options and menu.options[selected]
    if not item or item.disabled or item.readOnly then return end
    local fn=item.onSelect
    if fn then fn(item.args) end
    if item.shouldClose~=false then Menus[data.id]=nil end
end)

return Menu