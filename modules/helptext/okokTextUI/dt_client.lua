local adapter = { resource = 'okokTextUI', publicName = 'okokTextUI' }
local open = false
local current
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:show(data)
    local position = tostring(data.position or 'right'):find('left') and 'left' or 'right'
    local text = tostring(data.description or data.text or '')
    if data.keybind or data.key then
        text = (' [%s] %s'):format(data.keybind or data.key, text):sub(2)
    end
    exports.okokTextUI:Open(text, data.color or 'darkblue', position, data.playSound == true)
    open = true
    current = text
    return true
end
function adapter:hide()
    exports.okokTextUI:Close()
    open = false
    current = nil
    return true
end
function adapter:isOpen()
    return open, current
end
DT.Modules.Register('helptext', 'okokTextUI', adapter)
