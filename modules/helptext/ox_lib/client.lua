local A={resource='ox_lib',publicName='ox_lib'}
local function pos(position)
    local map={['center-left']='left-center',['centre-left']='left-center',['left-center']='left-center',['center-right']='right-center',['centre-right']='right-center',['right-center']='right-center',['top-left']='top-center',['top-right']='top-center',['bottom-left']='bottom-center',['bottom-right']='bottom-center',top='top-center',bottom='bottom-center'}
    position=tostring(position or DTConfig.UI.textUIPosition or 'right-center'):lower(); position=map[position] or position; if position~='right-center' and position~='left-center' and position~='top-center' and position~='bottom-center' then position='right-center' end; return position
end
local function text(d)
    local rows={}; if d.title and d.title~='' then rows[#rows+1]=('**%s**'):format(d.title) end; if d.description and d.description~='' then rows[#rows+1]=d.description end; if d.options then if #rows>0 then rows[#rows+1]='' end; for i=1,#d.options do local x=d.options[i]; if type(x)=='table' then local l=x.label or x.title or x.description or ''; local k=x.keybind or x.key; rows[#rows+1]=k and k~='' and ('`%s`  %s'):format(tostring(k),tostring(l)) or tostring(l) end end end; if #rows==0 then rows[1]='' end; return table.concat(rows,'\n')
end
function A:available() return DTUtils.isStarted(self.resource) end
function A:show(d)
    local style=DTUtils.copy(d.style or {}); style.maxWidth=style.maxWidth or '320px'; style.minWidth=style.minWidth or '260px'; style.whiteSpace=style.whiteSpace or 'pre-line'; style.lineHeight=style.lineHeight or '1.55'; style.borderRadius=style.borderRadius or '12px'; style.backgroundColor=style.backgroundColor or 'rgba(30, 31, 36, 0.96)'; style.color=style.color or '#E4E4E7'; style.padding=style.padding or '14px 16px'
    exports.ox_lib:showTextUI(text(d),{position=pos(d.position),icon=d.icon,iconColor=d.iconColor,iconAnimation=d.iconAnimation,alignIcon=d.alignIcon or 'top',style=style}); return true
end
function A:hide() exports.ox_lib:hideTextUI(); return true end
function A:isOpen() local ok,a,b=pcall(function() return exports.ox_lib:isTextUIOpen() end); return ok and a==true,b end
DT.Modules.Register('helptext','ox_lib',A)
