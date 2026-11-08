local adapter = { resource = 'native', publicName = 'native' }
function adapter:available()
    return true
end
function adapter:show(data)
    SendNUIMessage({
        action = 'textui:show',
        data = {
            title = data.title,
            description = data.description,
            text = data.description or data.title or '',
            icon = data.icon,
            iconColor = data.iconColor,
            options = data.options,
            position = data.position or DTConfig.UI.textUIPosition,
        },
    })
    return true
end
function adapter:hide()
    SendNUIMessage({ action = 'textui:hide', data = {} })
    return true
end
function adapter:isOpen()
    return false, nil
end
DT.Modules.Register('helptext', 'native', adapter)
