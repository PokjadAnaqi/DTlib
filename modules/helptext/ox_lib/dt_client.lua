local adapter = { resource = 'ox_lib', publicName = 'ox_lib' }
local function pos(position)
    local map = {
        ['center-left'] = 'left-center',
        ['centre-left'] = 'left-center',
        ['left-center'] = 'left-center',
        ['center-right'] = 'right-center',
        ['centre-right'] = 'right-center',
        ['right-center'] = 'right-center',
        ['top-left'] = 'top-center',
        ['top-right'] = 'top-center',
        ['bottom-left'] = 'bottom-center',
        ['bottom-right'] = 'bottom-center',
        top = 'top-center',
        bottom = 'bottom-center',
    }
    position = tostring(position or DTConfig.UI.textUIPosition or 'right-center'):lower()
    position = map[position] or position
    if
        position ~= 'right-center'
        and position ~= 'left-center'
        and position ~= 'top-center'
        and position ~= 'bottom-center'
    then
        position = 'right-center'
    end
    return position
end
local function text(data)
    local rows = {}
    if data.title and data.title ~= '' then
        rows[#rows + 1] = ('**%s**'):format(data.title)
    end
    if data.description and data.description ~= '' then
        rows[#rows + 1] = data.description
    end
    if data.options then
        if #rows > 0 then
            rows[#rows + 1] = ''
        end
        for index = 1, #data.options do
            local x = data.options[index]
            if type(x) == 'table' then
                local list = x.label or x.title or x.description or ''
                local key = x.keybind or x.key
                rows[#rows + 1] = key and key ~= '' and ('`%s`  %s'):format(tostring(key), tostring(list))
                    or tostring(list)
            end
        end
    end
    if #rows == 0 then
        rows[1] = ''
    end
    return table.concat(rows, '\n')
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:show(data)
    local style = DTUtils.copy(data.style or {})
    style.maxWidth = style.maxWidth or '320px'
    style.minWidth = style.minWidth or '260px'
    style.whiteSpace = style.whiteSpace or 'pre-line'
    style.lineHeight = style.lineHeight or '1.55'
    style.borderRadius = style.borderRadius or '12px'
    style.backgroundColor = style.backgroundColor or 'rgba(30, 31, 36, 0.96)'
    style.color = style.color or '#E4E4E7'
    style.padding = style.padding or '14px 16px'
    exports.ox_lib:showTextUI(text(data), {
        position = pos(data.position),
        icon = data.icon,
        iconColor = data.iconColor,
        iconAnimation = data.iconAnimation,
        alignIcon = data.alignIcon or 'top',
        style = style,
    })
    return true
end
function adapter:hide()
    exports.ox_lib:hideTextUI()
    return true
end
function adapter:isOpen()
    local ok, provider, secondary = pcall(function()
        return exports.ox_lib:isTextUIOpen()
    end)
    return ok and provider == true, secondary
end
DT.Modules.Register('helptext', 'ox_lib', adapter)
