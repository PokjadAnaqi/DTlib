local A={resource='lation_ui',publicName='lation_ui'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:await(data)
    local d=DTUtils.copy(data)
    d.header=d.header or d.title
    d.content=d.content or d.description
    return exports.lation_ui:alert(d)
end
function A:close() exports.lation_ui:closeAlert(); return true end
DT.Modules.Register('alert','lation_ui',A)
