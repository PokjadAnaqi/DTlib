local adapter = { resource = 'lation_ui', publicName = 'lation_ui' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:send(payload)
    exports.lation_ui:notify(payload)
    return true
end
DT.Modules.Register('notify', 'lation_ui', adapter)
