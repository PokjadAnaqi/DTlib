local A={resource='Renewed-Weathersync',publicName='Renewed-Weathersync'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:getCurrent() local s=GlobalState.weather; if type(s)=='table' then return s.weather or s.currentWeather or s.type end; return type(s)=='string' and s or nil end
function A:getTime() local t=GlobalState.currentTime; if type(t)=='table' then return {hour=t.hour or GetClockHours(),minute=t.minute or GetClockMinutes(),second=t.second or GetClockSeconds()} end; return {hour=GetClockHours(),minute=GetClockMinutes(),second=GetClockSeconds()} end
DT.Modules.Register('weather','Renewed-Weathersync',A)
