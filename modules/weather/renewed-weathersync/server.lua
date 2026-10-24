local A={resource='Renewed-Weathersync',publicName='Renewed-Weathersync'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:getCurrent() local s=GlobalState.weather; if type(s)=='table' then return s.weather or s.currentWeather or s.type end; return type(s)=='string' and s or nil end
function A:getTime() local t=GlobalState.currentTime; return type(t)=='table' and DTUtils.copy(t) or nil end
DT.Modules.Register('weather','Renewed-Weathersync',A)
