local A={resource='okokTextUI',publicName='okokTextUI'}
local open=false;local current
function A:available() return DTUtils.isStarted(self.resource) end
function A:show(d)
    local position=tostring(d.position or 'right'):find('left') and 'left' or 'right'
    local text=tostring(d.description or d.text or '')
    if d.keybind or d.key then text=(' [%s] %s'):format(d.keybind or d.key,text):sub(2) end
    exports.okokTextUI:Open(text,d.color or 'darkblue',position,d.playSound==true)
    open=true;current=text;return true
end
function A:hide() exports.okokTextUI:Close();open=false;current=nil;return true end
function A:isOpen() return open,current end
DT.Modules.Register('helptext','okokTextUI',A)
