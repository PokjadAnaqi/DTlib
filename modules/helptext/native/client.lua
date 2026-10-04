local A={resource='native',publicName='native'}
function A:available() return true end
function A:show(d) SendNUIMessage({action='textui:show',data={title=d.title,description=d.description,text=d.description or d.title or '',icon=d.icon,iconColor=d.iconColor,options=d.options,position=d.position or DTConfig.UI.textUIPosition}}); return true end
function A:hide() SendNUIMessage({action='textui:hide',data={}}); return true end
function A:isOpen() return false,nil end
DT.Modules.Register('helptext','native',A)
