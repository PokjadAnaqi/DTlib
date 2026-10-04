local A={resource='standalone',publicName='standalone'}
function A:available() return true end
function A:getJobs() return {} end
function A:getGangs() return {} end
function A:getVehicles() return {} end
function A:getWeapons() return {} end
function A:getPlayer() return nil end
function A:getPlayers() local o={}; for _,s in ipairs(GetPlayers()) do o[#o+1]=tonumber(s) or s end; return o end
function A:getName(source) return GetPlayerName(source) end
function A:getGroups() return {} end
function A:getMoney() return 0 end
function A:getData() return {} end
DT.Modules.Register('framework','standalone',A)
