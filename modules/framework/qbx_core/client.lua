local U = DT.FrameworkUtil
local A = { resource = 'qbx_core', publicName = 'qbx' }

function A:available() return DTUtils.isStarted(self.resource) end
function A:getData()
    if rawget(_G, 'QBX') and QBX.PlayerData then return QBX.PlayerData end
    if DT.Callback and DT.Callback.Await then
        local ok, data = pcall(DT.Callback.Await, 'DTlib:internal:getPlayerData')
        return ok and data or {}
    end
    return {}
end
function A:getGroups()
    local ok, groups = pcall(function() return exports.qbx_core:GetGroups() end)
    return ok and groups or {}
end
function A:hasGroup(filter)
    local ok, value = pcall(function() return exports.qbx_core:HasGroup(filter) end)
    return ok and value == true
end
function A:hasPrimaryGroup(filter)
    local ok, value = pcall(function() return exports.qbx_core:HasPrimaryGroup(filter) end)
    return ok and value == true
end
function A:getJob() return U.normalizeGroup(self:getData().job) end
function A:getGang() return U.normalizeGroup(self:getData().gang) end
function A:getMeta(key)
    local data = self:getData(); local metadata = data.metadata or data.meta
    return metadata and metadata[key] or nil
end
function A:getCoords() return GetEntityCoords(PlayerPedId()) end
function A:getName()
    local data = self:getData(); local char = data.charinfo or {}
    local name = DTUtils.trim(('%s %s'):format(char.firstname or '', char.lastname or ''))
    return name ~= '' and name or data.name or GetPlayerName(PlayerId())
end

DT.Modules.Register('framework', 'qbx_core', A)
