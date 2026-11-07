local aliases = {
    renewed = 'Renewed-Weathersync',
    qb = 'qb-weathersync',
    easytime = 'cd_easytime',
    ['cd-easytime'] = 'cd_easytime',
    native = 'native',
}
local function resolveAdapter()
    return DT.Modules.Resolve(
        'weather',
        DTConfig.Adapters.weather,
        { 'Renewed-Weathersync', 'cd_easytime', 'qb-weathersync' },
        aliases,
        'native'
    )
end
function DT.Weather.Name()
    local adapter = resolveAdapter()
    return adapter and adapter.publicName or 'native'
end
function DT.Weather.GetCurrent()
    local adapter = resolveAdapter()
    return adapter and adapter.getCurrent and adapter:getCurrent() or nil
end
function DT.Weather.GetTime()
    local adapter = resolveAdapter()
    return adapter and adapter.getTime and adapter:getTime() or nil
end

function DT.Weather.GetData()
    local adapter = resolveAdapter()
    return adapter and adapter.getData and adapter:getData() or nil
end
