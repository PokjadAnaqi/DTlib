local A={resource='lation_ui',publicName='lation_ui'}
local function pos(position)
    local map={['center-left']='left-center',['centre-left']='left-center',['left-center']='left-center',['center-right']='right-center',['centre-right']='right-center',['right-center']='right-center',top='top-center',bottom='bottom-center'}
    position=tostring(position or DTConfig.UI.textUIPosition or 'right-center'):lower(); return map[position] or position
end
local function opts(items,fallback)
    if type(items)~='table' then return nil end; local out={}; for i=1,#items do local x=items[i]; if type(x)=='table' then out[#out+1]={label=x.label or x.title or x.description or '',icon=x.icon,iconColor=x.iconColor or fallback,iconAnimation=x.iconAnimation,keybind=x.keybind or x.key} end end; return #out>0 and out or nil
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:show(d) exports.lation_ui:showText({title=d.title,description=d.description,position=pos(d.position),icon=d.icon,iconColor=d.iconColor,iconAnimation=d.iconAnimation,keybind=d.keybind or d.key,options=opts(d.options,d.iconColor),bgColor=d.bgColor,txtColor=d.txtColor}); return true end
function A:hide() exports.lation_ui:hideText(); return true end
function A:isOpen() local ok,a,b=pcall(function() return exports.lation_ui:isOpen() end); return ok and a==true,b end
DT.Modules.Register('helptext','lation_ui',A)
