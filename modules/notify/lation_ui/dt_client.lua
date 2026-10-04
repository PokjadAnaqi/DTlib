local A={resource='lation_ui',publicName='lation_ui'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:send(p) exports.lation_ui:notify(p); return true end
DT.Modules.Register('notify','lation_ui',A)
