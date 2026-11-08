local adapter = { resource = 'lation_ui', publicName = 'lation_ui' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:await(data)
    local details = DTUtils.copy(data)
    details.header = details.header or details.title
    details.content = details.content or details.description
    return exports.lation_ui:alert(details)
end
function adapter:close()
    exports.lation_ui:closeAlert()
    return true
end
DT.Modules.Register('alert', 'lation_ui', adapter)
