local currentState = nil

local function providerName()
    local n = DT.UI.Name()
    return n == 'lation_ui' and 'lation_ui' or n == 'ox_lib' and 'ox_lib' or 'native'
end

local function A()
    return DT.UI.Adapter('helptext')
end

local function normalize(text, options)
    local d

    if type(text) == 'table' then
        d = DTUtils.copy(text)
    else
        d = DTUtils.copy(options or {})
        d.description = d.description or text or ''
    end

    d.description = d.description or d.text or ''
    d.position = d.position or DTConfig.UI.textUIPosition
    d.options = type(d.options) == 'table' and d.options or nil
    return d
end

local function remember(data)
    currentState = type(data) == 'table' and DTUtils.copy(data) or nil
end

function DT.TextUI.Show(text, options)
    local d = normalize(text, options)
    local a = A()
    local ok, err = pcall(a.show, a, d)

    if ok and err ~= false then
        remember(d)
        return true
    end

    DT.Debug('TextUI provider failed, using native:', err)
    local n = DT.Modules.Get('helptext', 'native')
    if n and n:show(d) then
        remember(d)
        return true
    end

    return false
end

function DT.TextUI.Hide(options)
    local preserveState = type(options) == 'table' and options.preserveState == true
    local a = A()
    local ok, result = pcall(a.hide, a)

    if ok and result ~= false then
        if not preserveState then remember(nil) end
        return true
    end

    local n = DT.Modules.Get('helptext', 'native')
    local hidden = n and n:hide() or false
    if hidden and not preserveState then remember(nil) end
    return hidden
end

function DT.TextUI.IsOpen()
    if currentState then
        return true, DTUtils.copy(currentState)
    end

    local a = A()
    if a and a.isOpen then
        return a:isOpen()
    end

    return false, nil
end

function DT.TextUI.GetState()
    return currentState and DTUtils.copy(currentState) or nil
end

function DT.TextUI.Restore(state)
    if type(state) ~= 'table' then return false end
    return DT.TextUI.Show(DTUtils.copy(state))
end

function DT.TextUI.ClearState()
    remember(nil)
    return true
end

exports('ShowTextUI', function(...) return DT.TextUI.Show(...) end)
exports('HideTextUI', function(...) return DT.TextUI.Hide(...) end)
exports('IsTextUIOpen', function(...) return DT.TextUI.IsOpen(...) end)
exports('GetTextUIState', function() return DT.TextUI.GetState() end)
exports('RestoreTextUI', function(state) return DT.TextUI.Restore(state) end)
