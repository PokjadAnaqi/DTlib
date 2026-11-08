local adapter = { resource = 'okokNotify', publicName = 'okokNotify' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:send(payload)
    local map = { info = 'Info', success = 'Success', warning = 'Warning', error = 'Error' }
    exports.okokNotify:Alert(
        payload.title or 'Notification',
        payload.message or '',
        payload.duration,
        map[payload.type] or 'Info',
        false
    )
    return true
end
DT.Modules.Register('notify', 'okokNotify', adapter)
