local A={resource='native',publicName='native'}
function A:available() return true end
function A:open(data,list) SetNuiFocus(true,true); SendNUIMessage({action='input:open',data={title=data.title or 'INPUT',description=data.description or data.subtitle,fields=list,submitText=data.submitText,cancelText=data.cancelText,cancel=data.cancel~=false}}); return true end
function A:close() SetNuiFocus(false,false); SendNUIMessage({action='input:close',data={}}); return true end
DT.Modules.Register('input','native',A)
