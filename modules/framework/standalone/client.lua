local adapter = { resource = 'standalone', publicName = 'standalone' }
function adapter:available()
    return true
end
function adapter:getData()
    return {}
end
function adapter:getGroups()
    return {}
end
function adapter:getJob()
    return nil
end
function adapter:getGang()
    return nil
end
function adapter:getMeta()
    return nil
end
function adapter:getStatus()
    return nil
end
function adapter:getCoords()
    return GetEntityCoords(PlayerPedId())
end
function adapter:getName()
    return GetPlayerName(PlayerId())
end
function adapter:hasPermission()
    return false
end
DT.Modules.Register('framework', 'standalone', adapter)
