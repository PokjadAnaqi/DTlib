local A={resource='lation_ui',publicName='lation_ui'}
local function position(position)
    local map={center=DTConfig.UI.menuPosition or 'offcenter-right',['center-left']='offcenter-left',['centre-left']='offcenter-left',['left-center']='offcenter-left',['center-right']='offcenter-right',['centre-right']='offcenter-right',['right-center']='offcenter-right'}
    position=tostring(position or DTConfig.UI.menuPosition or 'offcenter-right'):lower(); position=map[position] or position; if position~='top-left' and position~='top-right' and position~='offcenter-left' and position~='offcenter-right' then position=DTConfig.UI.menuPosition or 'offcenter-right' end; return position
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:open(id,data,items,onSelect,onExit)
    local out={}; for i=1,#items do local item=items[i]; local index=i; out[i]={title=item.title or item.label or ('Option %s'):format(index),description=item.description,icon=item.icon,iconColor=item.iconColor,iconAnimation=item.iconAnimation,keybind=item.keybind,disabled=item.disabled==true,readOnly=item.readOnly==true,shouldClose=item.shouldClose~=false and item.close~=false,menu=item.menu,arrow=item.arrow,progress=item.progress,progressColor=item.progressColor or item.colorScheme,image=item.image,metadata=item.metadata,onSelect=function() onSelect(index) end} end
    exports.lation_ui:registerMenu({id=id,title=data.title or 'DT MENU',subtitle=data.subtitle,headerIcon=data.headerIcon or data.icon,headerIconColor=data.headerIconColor,headerIconAnimation=data.headerIconAnimation,menu=data.menu,canClose=data.canClose~=false,position=position(data.position),options=out,onExit=onExit}); exports.lation_ui:showMenu(id); return id
end
function A:close() exports.lation_ui:hideMenu(); return true end
DT.Modules.Register('menu','lation_ui',A)
