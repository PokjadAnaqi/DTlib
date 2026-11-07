local adapter = { resource = 'ox_lib', publicName = 'ox_lib' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:send(payload)
    exports.ox_lib:notify({
        id = payload.id,
        title = payload.title,
        description = payload.message,
        type = payload.type == 'info' and 'inform' or payload.type,
        duration = payload.duration,
        position = payload.position,
        showDuration = payload.showDuration,
        style = payload.style,
        icon = payload.icon,
        iconColor = payload.iconColor,
        iconAnimation = payload.iconAnimation,
        alignIcon = payload.alignIcon,
        sound = payload.sound,
    })
    return true
end
DT.Modules.Register('notify', 'ox_lib', adapter)
