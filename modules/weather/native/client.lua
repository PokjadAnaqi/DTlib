local hashes={EXTRASUNNY=`EXTRASUNNY`,CLEAR=`CLEAR`,NEUTRAL=`NEUTRAL`,SMOG=`SMOG`,FOGGY=`FOGGY`,OVERCAST=`OVERCAST`,CLOUDS=`CLOUDS`,CLEARING=`CLEARING`,RAIN=`RAIN`,THUNDER=`THUNDER`,SNOW=`SNOW`,BLIZZARD=`BLIZZARD`,SNOWLIGHT=`SNOWLIGHT`,XMAS=`XMAS`,HALLOWEEN=`HALLOWEEN`}
local A={resource='native',publicName='native'}
function A:available() return true end
function A:getCurrent() for n,h in pairs(hashes) do if IsNextWeatherType(n) or GetPrevWeatherTypeHashName()==h or GetNextWeatherTypeHashName()==h then return n end end; return 'CLEAR' end
function A:getTime() return {hour=GetClockHours(),minute=GetClockMinutes(),second=GetClockSeconds()} end
DT.Modules.Register('weather','native',A)
