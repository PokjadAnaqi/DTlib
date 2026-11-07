local adapter = { resource = 'lation_ui', publicName = 'lation_ui' }
local function pos(position)
    local map = {
        ['center-left'] = 'left-center',
        ['centre-left'] = 'left-center',
        ['left-center'] = 'left-center',
        ['center-right'] = 'right-center',
        ['centre-right'] = 'right-center',
        ['right-center'] = 'right-center',
        top = 'top-center',
        bottom = 'bottom-center',
    }
    position = tostring(position or DTConfig.UI.textUIPosition or 'right-center'):lower()
    return map[position] or position
end
local function options(items, fallback)
    if type(items) ~= 'table' then
        return nil
    end
    local out = {}
    for index = 1, #items do
        local x = items[index]
        if type(x) == 'table' then
            out[#out + 1] = {
                label = x.label or x.title or x.description or '',
                icon = x.icon,
                iconColor = x.iconColor or fallback,
                iconAnimation = x.iconAnimation,
                keybind = x.keybind or x.key,
            }
        end
    end
    return #out > 0 and out or nil
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:show(data)
    exports.lation_ui:showText({
        title = data.title,
        description = data.description,
        position = pos(data.position),
        icon = data.icon,
        iconColor = data.iconColor,
        iconAnimation = data.iconAnimation,
        keybind = data.keybind or data.key,
        options = options(data.options, data.iconColor),
        bgColor = data.bgColor,
        txtColor = data.txtColor,
    })
    return true
end
function adapter:hide()
    exports.lation_ui:hideText()
    return true
end
function adapter:isOpen()
    local ok, provider, secondary = pcall(function()
        return exports.lation_ui:isOpen()
    end)
    return ok and provider == true, secondary
end
DT.Modules.Register('helptext', 'lation_ui', adapter)
