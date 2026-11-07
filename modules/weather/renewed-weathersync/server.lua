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
    return type(clockState) == 'table' and DTUtils.copy(clockState) or nil
end
DT.Modules.Register('weather', 'Renewed-Weathersync', adapter)
