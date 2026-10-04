local A={resource='ox_lib',publicName='ox_lib'}
local function position(position)
    local map={center='top-right',['center-left']='top-left',['centre-left']='top-left',['left-center']='top-left',['center-right']='top-right',['centre-right']='top-right',['right-center']='top-right',['offcenter-left']='top-left',['offcenter-right']='top-right'}
    position=tostring(position or 'top-right'):lower(); position=map[position] or position; if position~='top-left' and position~='top-right' and position~='bottom-left' and position~='bottom-right' then position='top-right' end; return position
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:open(id,data,items,onSelect,onExit)
    local out={}; for i=1,#items do local item=items[i]; local index=i; out[i]={title=item.title or item.label or ('Option %s'):format(index),description=item.description,icon=item.icon,iconColor=item.iconColor,iconAnimation=item.iconAnimation,disabled=item.disabled==true,readOnly=item.readOnly==true,menu=item.menu,arrow=item.arrow,progress=item.progress,colorScheme=item.colorScheme or item.progressColor,image=item.image,metadata=item.metadata,onSelect=function() onSelect(index) end} end
    exports.ox_lib:registerContext({id=id,title=data.title or 'DT MENU',position=position(data.position),menu=data.menu,canClose=data.canClose~=false,options=out,onExit=onExit,onBack=DTUtils.isCallable(data.onBack) and DTUtils.wrapCallable(data.onBack) or nil}); exports.ox_lib:showContext(id); return id
end
function A:close() exports.ox_lib:hideContext(false); return true end
DT.Modules.Register('menu','ox_lib',A)
