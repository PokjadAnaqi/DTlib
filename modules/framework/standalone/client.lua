local A = { resource = 'standalone', publicName = 'standalone' }
function A:available() return true end
function A:getData() return {} end
function A:getGroups() return {} end
function A:getJob() return nil end
function A:getGang() return nil end
function A:getMeta() return nil end
function A:getStatus() return nil end
function A:getCoords() return GetEntityCoords(PlayerPedId()) end
function A:getName() return GetPlayerName(PlayerId()) end
function A:hasPermission() return false end
DT.Modules.Register('framework','standalone',A)
