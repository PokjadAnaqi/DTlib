local U = DT.FrameworkUtil
local A = { resource = 'qbx_core', publicName = 'qbx' }

function A:available() return DTUtils.isStarted(self.resource) end
-- Resource-local snapshot. Never await an RPC from an exported GetData call.
local playerData, pending, nextRefresh = nil, nil, 0
local revision, loggedOut = 0, false
local function changed(data)
    playerData = data
    revision = revision + 1
    nextRefresh = GetGameTimer() + (next(data) and 60000 or 1000)
    TriggerEvent('DTlib:playerData:changed')
end
local function invalidate(unloaded)
    revision = revision + 1
    playerData, pending, nextRefresh = nil, nil, 0
    loggedOut = unloaded == true
    TriggerEvent('DTlib:playerData:changed')
end
function A:getData()
    if loggedOut or not self:available() then return {} end
    local now = GetGameTimer()
    if pending or now < nextRefresh then return playerData or {} end
    nextRefresh = now + 5000 -- failed compatibility hydration is backed off
    -- Qbox's official playerdata module uses this client export too.
    local ok, data = pcall(function() return exports.qbx_core:GetPlayerData() end)
    if ok and type(data) == 'table' then changed(data);return playerData end
    local qbx = rawget(_G, 'QBX')
    if qbx and type(qbx.PlayerData) == 'table' then changed(qbx.PlayerData);return playerData end
    if DT.Callback and DT.Callback.Await then
        local token = {revision = revision}
        pending = token
        CreateThread(function()
            -- Older Qbox builds can hydrate via the server, in DTlib's own coroutine.
            local success, value = pcall(DT.Callback.Await, 'DTlib:internal:getPlayerData')
            if pending ~= token then return end
            pending = nil
            if revision ~= token.revision or loggedOut or not A:available() then return end
            nextRefresh = GetGameTimer() + 5000
            if success and type(value) == 'table' then changed(value) end
        end)
    end
    return playerData or {}
end
RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    if not A:available() or type(data) ~= 'table' then return end
    if loggedOut and not (data.citizenid or data.identifier) then return end
    loggedOut = false
    changed(data)
end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    invalidate(false)
    A:getData()
end)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function() invalidate(true) end)
for event, field in pairs({['QBCore:Client:OnJobUpdate']='job', ['QBCore:Client:OnGangUpdate']='gang'}) do
    local key = field
    RegisterNetEvent(event, function(data)
        if not loggedOut and A:available() and playerData and type(data) == 'table' then
            playerData[key] = data
            changed(playerData)
        end
    end)
end
AddEventHandler('onClientResourceStop', function(resource)
    if resource == A.resource then invalidate(true) end
end)
AddEventHandler('onClientResourceStart', function(resource)
    if resource == A.resource then invalidate(false) end
end)
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
