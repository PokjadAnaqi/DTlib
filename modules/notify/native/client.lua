local adapter = { resource = 'native', publicName = 'native' }
function adapter:available()
    return true
end
function adapter:send(payload)
    local data = DTUtils.copy(payload)
    data.description = payload.message or ''
    data.title = payload.title or ''
    SendNUIMessage({ action = 'notify', data = data })
    return true
end
DT.Modules.Register('notify', 'native', adapter)
