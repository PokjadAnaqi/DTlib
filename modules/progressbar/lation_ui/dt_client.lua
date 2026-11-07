local adapter = { resource = 'lation_ui', publicName = 'lation_ui' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:run(data)
    return exports.lation_ui:progressBar({
        label = data.label or 'Processing...',
        description = data.description,
        duration = math.max(0, tonumber(data.duration) or 1000),
        icon = data.icon,
        iconColor = data.iconColor,
        iconAnimation = data.iconAnimation,
        color = data.color,
        steps = data.steps,
        canCancel = data.canCancel ~= false,
        useWhileDead = data.useWhileDead == true,
        allowRagdoll = data.allowRagdoll == true,
        allowCuffed = data.allowCuffed == true,
        allowFalling = data.allowFalling == true,
        allowSwimming = data.allowSwimming == true,
        anim = data.anim,
        prop = data.prop,
        disable = data.disable,
    })
end
function adapter:active()
    local ok, value = pcall(function()
        return exports.lation_ui:progressActive()
    end)
    return ok and value == true
end
function adapter:cancel()
    local ok = pcall(function()
        exports.lation_ui:cancelProgress()
    end)
    return ok
end
DT.Modules.Register('progressbar', 'lation_ui', adapter)
