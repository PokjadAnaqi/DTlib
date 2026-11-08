local adapter = { resource = 'Renewed-Weathersync', publicName = 'Renewed-Weathersync' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:getCurrent()
    local value = GlobalState.weather
    if type(value) == 'table' then
        return value.weather or value.currentWeather or value.type
    end
    return type(value) == 'string' and value or nil
end
function adapter:getTime()
    local clockState = GlobalState.currentTime
    if type(clockState) == 'table' then
        return {
            hour = clockState.hour or GetClockHours(),
            minute = clockState.minute or GetClockMinutes(),
            second = clockState.second or GetClockSeconds(),
        }
    end
    return { hour = GetClockHours(), minute = GetClockMinutes(), second = GetClockSeconds() }
end
DT.Modules.Register('weather', 'Renewed-Weathersync', adapter)
