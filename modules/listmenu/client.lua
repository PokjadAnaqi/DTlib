DT.ListMenu = DT.ListMenu or {}
local menus = {}
local active
local sequence = 0
local function backend()
    local configured = DTConfig.Adapters.listmenu
    if not configured or configured == 'auto' then
        configured = DTConfig.Adapters.ui or 'auto'
    end
    local aliases = { lation = 'lation_ui', lationui = 'lation_ui', ox = 'ox_lib', oxlib = 'ox_lib' }
    configured = aliases[configured] or configured
    if configured == 'native' or configured == 'dtlib' then
        return nil
    end
    return DTUtils.detect(configured, { 'lation_ui', 'ox_lib' })
end
local function exportCall(provider, method, ...)
    if not provider or not DTUtils.isStarted(provider) then
        error('provider_unavailable')
    end
    local arguments = table.pack(...)
    return exports[provider][method](exports[provider], table.unpack(arguments, 1, arguments.n))
end
local methods = {
    lation_ui = {
        register = 'registerListMenu',
        show = 'showListMenu',
        hide = 'hideListMenu',
        set = 'setListMenuOptions',
        get = 'getOpenListMenu',
    },
    ox_lib = {
        register = 'registerMenu',
        show = 'showMenu',
        hide = 'hideMenu',
        set = 'setMenuOptions',
        get = 'getOpenMenu',
    },
}
local function callback(handler)
    return DTUtils.wrapCallable(handler)
end
function DT.ListMenu.Register(data, completionCallback)
    assert(type(data) == 'table' and type(data.id) == 'string', 'DT.ListMenu.Register requires a string id')
    local payload = backend()
    if not payload then
        return nil, 'provider_unavailable'
    end
    local details = DTUtils.copy(data)
    details.options = details.options or details.items or {}
    details.items = nil
    details.position = details.position or 'top-right'
    if details.position == 'offcenter-right' or details.position == 'right-center' then
        details.position = 'top-right'
    end
    if details.position == 'offcenter-left' or details.position == 'left-center' then
        details.position = 'top-left'
    end
    local options = details.options
    local dispatch = callback(completionCallback)
    for _, key in ipairs({ 'onClose', 'onSelected', 'onSideScroll', 'onCheck' }) do
        details[key] = callback(details[key])
    end
    local close = details.onClose
    details.onClose = function(key)
        active = nil
        if close then
            close(key)
        end
    end
    for entryKey, item in ipairs(options) do
        item.label = item.label or item.title or ('Option %d'):format(entryKey)
        item.close = item.close ~= false and item.shouldClose ~= false
        item.disabled = item.disabled == true or item.readOnly == true
        -- Central dispatch below executes selections once for both backends.
        item.onSelect = nil
        item.event = nil
        item.serverEvent = nil
    end
    local originals = data.options or data.items or {}
    local function select(index, scroll, arguments, checked)
        local item = originals[index]
        if not item or item.disabled or item.readOnly then
            return
        end
        if item.close ~= false and item.shouldClose ~= false then
            active = nil
        end
        if DTUtils.isCallable(item.onSelect) then
            DTUtils.safeCall(item.onSelect, index, scroll, arguments, checked)
        end
        if dispatch then
            dispatch(index, scroll, arguments, checked)
        end
        if item.event then
            TriggerEvent(item.event, arguments)
        end
        if item.serverEvent then
            TriggerServerEvent(item.serverEvent, arguments)
        end
        if item.command then
            ExecuteCommand(item.command)
        end
    end
    local ok, errorMessage = pcall(exportCall, payload, methods[payload].register, details, select)
    if not ok then
        return nil, tostring(errorMessage)
    end
    menus[data.id] = { provider = payload, data = details, callback = select, originals = originals }
    return data.id
end
function DT.ListMenu.Show(id, startIndex)
    local methodName = menus[id]
    if not methodName then
        return false, 'unknown_menu'
    end
    local ok, errorMessage = pcall(exportCall, methodName.provider, methods[methodName.provider].show, id, startIndex)
    if not ok then
        return false, tostring(errorMessage)
    end
    active = id
    return true
end
function DT.ListMenu.Open(data, completionCallback)
    sequence = sequence + 1
    data = DTUtils.copy(data or {})
    data.id = data.id or ('dtlib_list_%d'):format(sequence)
    local id, errorMessage = DT.ListMenu.Register(data, completionCallback)
    if not id then
        return nil, errorMessage
    end
    local ok, reason = DT.ListMenu.Show(id, data.startIndex)
    return ok and id or nil, reason
end
function DT.ListMenu.Close(onExit)
    local methodName = active and menus[active]
    if not methodName then
        return false
    end
    local ok, errorMessage = pcall(exportCall, methodName.provider, methods[methodName.provider].hide, onExit == true)
    if ok then
        active = nil
        return true
    end
    return false, tostring(errorMessage)
end
function DT.ListMenu.SetOptions(id, options, index)
    local methodName = menus[id]
    if not methodName then
        return false, 'unknown_menu'
    end
    if index then
        methodName.originals[index] = options
    else
        for key in pairs(methodName.originals) do
            methodName.originals[key] = nil
        end
        for key, value in pairs(options) do
            methodName.originals[key] = value
        end
    end
    -- Reuse the original table referenced by the registration callback.
    if index then
        methodName.data.options[index] = DTUtils.copy(options)
    else
        methodName.data.options = DTUtils.copy(options)
    end
    local list = index and { methodName.data.options[index] } or methodName.data.options
    for _, item in ipairs(list) do
        item.label = item.label or item.title
        item.disabled = item.disabled == true or item.readOnly == true
        item.close = item.close ~= false and item.shouldClose ~= false
        item.onSelect = nil
        item.event = nil
        item.serverEvent = nil
    end
    local ok, errorMessage = pcall(
        exportCall,
        methodName.provider,
        methods[methodName.provider].set,
        id,
        index and methodName.data.options[index] or methodName.data.options,
        index
    )
    return ok, not ok and tostring(errorMessage) or nil
end
function DT.ListMenu.GetOpen()
    local methodName = active and menus[active]
    if not methodName then
        return nil
    end
    local ok, result = pcall(exportCall, methodName.provider, methods[methodName.provider].get)
    if ok then
        active = result
        return result
    end
end
DT.ListMenu.Provider = backend
DT.UI.ListMenu = DT.ListMenu.Open
for name, method in pairs({
    RegisterListMenu = 'Register',
    ShowListMenu = 'Show',
    ListMenuOpen = 'Open',
    HideListMenu = 'Close',
    SetListMenuOptions = 'SetOptions',
    GetOpenListMenu = 'GetOpen',
}) do
    local handler = method
    exports(name, function(...)
        return DT.ListMenu[handler](...)
    end)
end
