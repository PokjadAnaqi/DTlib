local A={resource='native',publicName='native'}
function A:available() return true end
function A:open(id,data,items)
    local out={}; for i=1,#items do local x=items[i]; out[i]={label=x.label or x.title,description=x.description,rightLabel=x.rightLabel,disabled=x.disabled==true} end
    SetNuiFocus(true,true); SendNUIMessage({action='menu:open',data={id=id,title=data.title or 'DT MENU',subtitle=data.subtitle,position=data.position or 'center',items=out}}); return id
end
function A:close() SetNuiFocus(false,false); SendNUIMessage({action='menu:close',data={}}); return true end
DT.Modules.Register('menu','native',A)
