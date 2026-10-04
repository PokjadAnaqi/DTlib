local A={resource='qb-weathersync',publicName='qb-weathersync'}
function A:available() return DTUtils.isStarted(self.resource) end
function A:getCurrent() local ok,v=pcall(function() return exports['qb-weathersync']:getWeatherState() end); return ok and v or nil end
function A:getTime() return {hour=GetClockHours(),minute=GetClockMinutes(),second=GetClockSeconds()} end
DT.Modules.Register('weather','qb-weathersync',A)
