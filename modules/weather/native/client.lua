local hashes = {
    EXTRASUNNY = `EXTRASUNNY`,
    CLEAR = `CLEAR`,
    NEUTRAL = `NEUTRAL`,
    SMOG = `SMOG`,
    FOGGY = `FOGGY`,
    OVERCAST = `OVERCAST`,
    CLOUDS = `CLOUDS`,
    CLEARING = `CLEARING`,
    RAIN = `RAIN`,
    THUNDER = `THUNDER`,
    SNOW = `SNOW`,
    BLIZZARD = `BLIZZARD`,
    SNOWLIGHT = `SNOWLIGHT`,
    XMAS = `XMAS`,
    HALLOWEEN = `HALLOWEEN`,
}
local adapter = { resource = 'native', publicName = 'native' }
function adapter:available()
    return true
end
function adapter:getCurrent()
    for key, handle in pairs(hashes) do
        if
            IsNextWeatherType(key)
            or GetPrevWeatherTypeHashName() == handle
            or GetNextWeatherTypeHashName() == handle
        then
            return key
        end
    end
    return 'CLEAR'
end
function adapter:getTime()
    return { hour = GetClockHours(), minute = GetClockMinutes(), second = GetClockSeconds() }
end
DT.Modules.Register('weather', 'native', adapter)
