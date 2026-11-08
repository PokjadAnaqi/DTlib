local currentState = nil

local function providerName()
    local uiProvider = DT.UI.Name()
    return uiProvider == 'lation_ui' and 'lation_ui' or uiProvider == 'ox_lib' and 'ox_lib' or 'native'
end

local function resolveAdapter()
    return DT.UI.Adapter('helptext')
end

local function normalize(text, options)
    local details

    if type(text) == 'table' then
        details = DTUtils.copy(text)
    else
        details = DTUtils.copy(options or {})
        details.description = details.description or text or ''
    end

    details.description = details.description or details.text or ''
    details.position = details.position or DTConfig.UI.textUIPosition
    details.options = type(details.options) == 'table' and details.options or nil
    return details
end

local function remember(data)
    currentState = type(data) == 'table' and DTUtils.copy(data) or nil
end

function DT.TextUI.Show(text, options)
    local details = normalize(text, options)
    local adapter = resolveAdapter()
    local ok, errorMessage = pcall(adapter.show, adapter, details)

    if ok and errorMessage ~= false then
        remember(details)
        return true
    end

    DT.Debug('TextUI provider failed, using native:', errorMessage)
    local provider = DT.Modules.Get('helptext', 'native')
    if provider and provider:show(details) then
        remember(details)
        return true
    end

    return false
end

function DT.TextUI.Hide(options)
    local preserveState = type(options) == 'table' and options.preserveState == true
    local adapter = resolveAdapter()
    local ok, result = pcall(adapter.hide, adapter)

    if ok and result ~= false then
        if not preserveState then
            remember(nil)
        end
        return true
    end

    local provider = DT.Modules.Get('helptext', 'native')
    local hidden = provider and provider:hide() or false
    if hidden and not preserveState then
        remember(nil)
    end
    return hidden
end

function DT.TextUI.IsOpen()
    if currentState then
        return true, DTUtils.copy(currentState)
    end

    local adapter = resolveAdapter()
    if adapter and adapter.isOpen then
        return adapter:isOpen()
    end

    return false, nil
end

function DT.TextUI.GetState()
    return currentState and DTUtils.copy(currentState) or nil
end

function DT.TextUI.Restore(state)
    if type(state) ~= 'table' then
        return false
    end
    return DT.TextUI.Show(DTUtils.copy(state))
end

function DT.TextUI.ClearState()
    remember(nil)
    return true
end

exports('ShowTextUI', function(...)
    return DT.TextUI.Show(...)
end)
exports('HideTextUI', function(...)
    return DT.TextUI.Hide(...)
end)
exports('IsTextUIOpen', function(...)
    return DT.TextUI.IsOpen(...)
end)
exports('GetTextUIState', function()
    return DT.TextUI.GetState()
end)
exports('RestoreTextUI', function(state)
    return DT.TextUI.Restore(state)
end)
