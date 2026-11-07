local adapter = {
    resource = 'cd_easytime',
    publicName = 'cd_easytime',
}

local function normalizeWeather(value)
    if type(value) == 'table' then
        value = value.weather or value.currentWeather or value.current_weather or value.type or value.name
    end
    if type(value) ~= 'string' or value == '' then
        return nil
    end
    return value:upper()
end

local function readData()
    local ok, data = pcall(function()
        return exports[adapter.resource]:GetAllData()
    end)

    if ok and type(data) == 'table' then
        return data
    end

    ok, data = pcall(function()
        return exports[adapter.resource]:GetWeather()
    end)

    if ok then
        return data
    end
    return nil
end

function adapter:available()
    return DTUtils.isStarted(self.resource)
end

function adapter:getCurrent()
    local data = readData()
    return normalizeWeather(data)
end

function adapter:getTime()
    local data = readData()
    if type(data) ~= 'table' then
        return nil
    end

    local hour = tonumber(data.hours or data.hour)
    if hour == nil then
        return nil
    end

    return {
        hour = hour,
        minute = tonumber(data.mins or data.minutes or data.minute) or 0,
        second = tonumber(data.seconds or data.second) or 0,
    }
end

function adapter:getData()
    local data = readData()
    if type(data) ~= 'table' then
        return nil
    end
    return DTUtils.copy(data)
end

DT.Modules.Register('weather', 'cd_easytime', adapter)
