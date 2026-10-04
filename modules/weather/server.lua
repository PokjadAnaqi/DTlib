local aliases={renewed='Renewed-Weathersync',qb='qb-weathersync',native='native'}
local function A() return DT.Modules.Resolve('weather',DTConfig.Adapters.weather,{'Renewed-Weathersync','qb-weathersync'},aliases,'native') end
function DT.Weather.Name() local a=A(); return a and a.publicName or 'native' end
function DT.Weather.GetCurrent() local a=A(); return a and a.getCurrent and a:getCurrent() or nil end
function DT.Weather.GetTime() local a=A(); return a and a.getTime and a:getTime() or nil end
