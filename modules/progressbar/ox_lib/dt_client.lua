local adapter = { resource = 'ox_lib', publicName = 'ox_lib' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:run(data)
    local payload = {
        duration = math.max(0, tonumber(data.duration) or 1000),
        label = data.label or 'Processing...',
        useWhileDead = data.useWhileDead == true,
        allowRagdoll = data.allowRagdoll == true,
        allowSwimming = data.allowSwimming == true,
        allowCuffed = data.allowCuffed == true,
        allowFalling = data.allowFalling == true,
        canCancel = data.canCancel ~= false,
        anim = data.anim,
        prop = data.prop,
        disable = data.disable,
    }
    local circle = data.circle == true or data.variant == 'circle' or data.type == 'circle'
    if circle then
        local pos = tostring(data.position or 'middle'):lower()
        payload.position = (pos == 'bottom' or pos == 'bottom-center') and 'bottom' or 'middle'
        return exports.ox_lib:progressCircle(payload)
    end
    return exports.ox_lib:progressBar(payload)
end
function adapter:active()
    local ok, value = pcall(function()
        return exports.ox_lib:progressActive()
    end)
    return ok and value == true
end
function adapter:cancel()
    local ok = pcall(function()
        exports.ox_lib:cancelProgress()
    end)
    return ok
end
DT.Modules.Register('progressbar', 'ox_lib', adapter)
