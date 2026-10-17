local A={resource='native',publicName='native'}
function A:available() return true end
function A:open(id,data,items)
    local out={}; for i=1,#items do local x=items[i]; out[i]={label=x.label or x.title,description=x.description,rightLabel=x.rightLabel,disabled=x.disabled==true,readOnly=x.readOnly==true,icon=x.icon,iconColor=x.iconColor,image=x.image,metadata=x.metadata,progress=x.progress,progressColor=x.progressColor or x.colorScheme} end
    SetNuiFocus(true,true); SendNUIMessage({action='menu:open',data={id=id,title=data.title or 'DT MENU',subtitle=data.subtitle,position=data.position or 'center',canClose=data.canClose~=false,items=out}}); return id
end
function A:close() SetNuiFocus(false,false); SendNUIMessage({action='menu:close',data={}}); return true end
DT.Modules.Register('menu','native',A)
