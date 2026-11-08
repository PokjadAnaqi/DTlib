local adapter = { resource = 'standalone', publicName = 'standalone' }
function adapter:available()
    return true
end
function adapter:getJobs()
    return {}
end
function adapter:getGangs()
    return {}
end
function adapter:getVehicles()
    return {}
end
function adapter:getWeapons()
    return {}
end
function adapter:getPlayer()
    return nil
end
function adapter:getPlayers()
    local result = {}
    for _, value in ipairs(GetPlayers()) do
        result[#result + 1] = tonumber(value) or value
    end
    return result
end
function adapter:getName(source)
    return GetPlayerName(source)
end
function adapter:getGroups()
    return {}
end
function adapter:getMoney()
    return 0
end
function adapter:getData()
    return {}
end
DT.Modules.Register('framework', 'standalone', adapter)
