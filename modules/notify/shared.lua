DT.NotifyUtil = DT.NotifyUtil or {}
local notifyUtil = DT.NotifyUtil
notifyUtil.validTypes = { info = true, success = true, warning = true, error = true }
notifyUtil.validPositions = {
    ['top-left'] = true,
    top = true,
    ['top-right'] = true,
    ['center-left'] = true,
    ['center-right'] = true,
    ['bottom-left'] = true,
    bottom = true,
    ['bottom-right'] = true,
}
notifyUtil.validSizes = { sm = true, md = true, lg = true }

function notifyUtil.type(value)
    value = tostring(value or 'info'):lower()
    if value == 'inform' or value == 'primary' or value == 'default' then
        value = 'info'
    end
    if value == 'danger' or value == 'fail' or value == 'failed' then
        value = 'error'
    end
    if value == 'warn' then
        value = 'warning'
    end
    return notifyUtil.validTypes[value] and value or 'info'
end
function notifyUtil.position(value)
    if notifyUtil.validPositions[value] then
        return value
    end

    local defaultPosition = DTConfig.UI.notifyPosition
    return notifyUtil.validPositions[defaultPosition] and defaultPosition or 'top-right'
end
function notifyUtil.resolveText(text)
    if DTConfig.UI.resolveItemLabels == false or type(text) ~= 'string' or text == '' then
        return text
    end
    return (
        text:gsub('([%w_%-]+)', function(token)
            local label = DT.Inventory and DT.Inventory.GetItemLabel and DT.Inventory.GetItemLabel(token)
            return label and label ~= token and label or token
        end)
    )
end
function notifyUtil.payload(data, description, notifyType)
    if type(data) == 'string' then
        data = { title = data, description = description, type = notifyType }
    else
        data = DTUtils.copy(data or {})
    end
    local payload = {
        expiresAt = tonumber(data.expiresAt),
        serverTime = IsDuplicityVersion() and os.time() or tonumber(data.serverTime),
        layout = data.layout == 'banner' and 'banner' or nil,
        subtitle = notifyUtil.resolveText(data.subtitle or data.subject),
        image = data.image,
        progress = data.progress,
        countdown = data.countdown,
        persistent = data.persistent == true,
        stack = data.stack,
        maxVisible = math.max(1, math.min(8, tonumber(DTConfig.UI.notifyMaxVisible) or 5)),
        id = data.id,
        title = notifyUtil.resolveText(data.title),
        message = notifyUtil.resolveText(data.message or data.description),
        type = notifyUtil.type(data.type),
        duration = math.max(0, tonumber(data.duration) or DTConfig.UI.notifyDuration or 4500),
        position = notifyUtil.position(data.position),
        size = notifyUtil.validSizes[data.size] and data.size or (DTConfig.UI.notifySize or 'md'),
        icon = data.icon,
        iconColor = data.iconColor,
        iconAnimation = data.iconAnimation,
        bgColor = data.bgColor,
        txtColor = data.txtColor,
        titleColor = data.titleColor,
        sound = data.sound,
        showDuration = data.showDuration,
        style = data.style,
        alignIcon = data.alignIcon,
    }
    if not payload.title and not payload.message then
        payload.title = 'NOTIFICATION'
    end
    return payload
end
