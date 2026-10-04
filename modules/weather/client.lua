local aliases={renewed='Renewed-Weathersync',qb='qb-weathersync',easytime='cd_easytime',['cd-easytime']='cd_easytime',native='native'}
local function A() return DT.Modules.Resolve('weather',DTConfig.Adapters.weather,{'Renewed-Weathersync','cd_easytime','qb-weathersync'},aliases,'native') end
function DT.Weather.Name() local a=A(); return a and a.publicName or 'native' end
function DT.Weather.GetCurrent() local a=A(); return a and a.getCurrent and a:getCurrent() or 'CLEAR' end
function DT.Weather.GetTime() local a=A(); return a and a.getTime and a:getTime() or {hour=GetClockHours(),minute=GetClockMinutes(),second=GetClockSeconds()} end

function DT.Weather.GetData() local a=A(); return a and a.getData and a:getData() or nil end
