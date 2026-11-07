local adapter = { resource = 'qb-weathersync', publicName = 'qb-weathersync' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:getCurrent()
    local ok, value = pcall(function()
        return exports['qb-weathersync']:getWeatherState()
    end)
    return ok and value or nil
end
function adapter:getTime()
    return { hour = GetClockHours(), minute = GetClockMinutes(), second = GetClockSeconds() }
end
DT.Modules.Register('weather', 'qb-weathersync', adapter)
