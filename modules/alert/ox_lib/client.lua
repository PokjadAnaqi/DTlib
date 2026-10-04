local A={resource='ox_lib',publicName='ox_lib'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:await(d) return exports.ox_lib:alertDialog({header=d.header or d.title or 'CONFIRM',content=d.content or d.description or '',centered=d.centered==true,cancel=d.cancel~=false,size=d.size,overflow=d.overflow,labels=d.labels}) end
function A:close() exports.ox_lib:closeAlertDialog(); return true end
DT.Modules.Register('alert','ox_lib',A)
