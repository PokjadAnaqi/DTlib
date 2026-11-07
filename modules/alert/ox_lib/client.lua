local adapter = { resource = 'ox_lib', publicName = 'ox_lib' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:await(data)
    return exports.ox_lib:alertDialog({
        header = data.header or data.title or 'CONFIRM',
        content = data.content or data.description or '',
        centered = data.centered == true,
        cancel = data.cancel ~= false,
        size = data.size,
        overflow = data.overflow,
        labels = data.labels,
    })
end
function adapter:close()
    exports.ox_lib:closeAlertDialog()
    return true
end
DT.Modules.Register('alert', 'ox_lib', adapter)
