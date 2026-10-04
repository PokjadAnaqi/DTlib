local A={resource='okokNotify',publicName='okokNotify'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:send(p)
    local map={info='Info',success='Success',warning='Warning',error='Error'}
    exports.okokNotify:Alert(p.title or 'Notification',p.message or '',p.duration,map[p.type] or 'Info',false); return true
end
DT.Modules.Register('notify','okokNotify',A)
