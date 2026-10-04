local config = DTConfig.Waypoint or {}
DT.Waypoint = DT.Waypoint or {}

local enabled = config.enabled == true
local nextId = 0
local waypoints = {}
local byPlayer = {}

local function resolveTargets(target)
    if target == -1 or target == 'all' then
        local players = GetPlayers()
        local result = {}
        for i = 1, #players do result[#result + 1] = tonumber(players[i]) end
        return result
    end

    if type(target) == 'number' then return { target } end
    if type(target) ~= 'table' then return {} end

    local result, seen = {}, {}
    for i = 1, #target do
        local id = tonumber(target[i])
        if id and id > 0 and not seen[id] then
            seen[id] = true
            result[#result + 1] = id
        end
    end
    return result
end

local function targetContains(target, playerId)
    if target == -1 or target == 'all' then return true end
    if type(target) == 'number' then return target == playerId end
    if type(target) ~= 'table' then return false end
    for i = 1, #target do
        if tonumber(target[i]) == playerId then return true end
    end
    return false
end

local function trackPlayer(id, waypointId)
    byPlayer[id] = byPlayer[id] or {}
    byPlayer[id][waypointId] = true
end

local function untrackPlayer(id, waypointId)
    local set = byPlayer[id]
    if not set then return end
    set[waypointId] = nil
    if not next(set) then byPlayer[id] = nil end
end

local function triggerTargets(target, event, ...)
    if target == -1 or target == 'all' then
        TriggerClientEvent(event, -1, ...)
        return
    end
    local targets = resolveTargets(target)
    for i = 1, #targets do TriggerClientEvent(event, targets[i], ...) end
end

function DT.Waypoint.Enabled()
    return enabled
end

function DT.Waypoint.Create(target, data)
    if not enabled then return nil, 'disabled' end
    if type(data) ~= 'table' or data.coords == nil then return nil, 'invalid_data' end

    nextId = nextId + 1
    local id = nextId
    local entry = {
        id = id,
        target = target,
        data = data,
        createdAt = os.time(),
    }
    waypoints[id] = entry

    local targets = resolveTargets(target)
    for i = 1, #targets do trackPlayer(targets[i], id) end

    triggerTargets(target, 'DTlib:waypoint:create', id, data)
    return id
end

function DT.Waypoint.Update(id, patch)
    if not enabled then return false, 'disabled' end
    id = tonumber(id)
    local entry = id and waypoints[id]
    if not entry then return false, 'not_found' end
    if type(patch) ~= 'table' then return false, 'invalid_data' end

    for key, value in pairs(patch) do entry.data[key] = value end
    triggerTargets(entry.target, 'DTlib:waypoint:update', id, patch)
    return true
end

function DT.Waypoint.Remove(id)
    if not enabled then return false, 'disabled' end
    id = tonumber(id)
    local entry = id and waypoints[id]
    if not entry then return false, 'not_found' end

    triggerTargets(entry.target, 'DTlib:waypoint:remove', id)
    local targets = resolveTargets(entry.target)
    for i = 1, #targets do untrackPlayer(targets[i], id) end
    waypoints[id] = nil
    return true
end

function DT.Waypoint.RemoveAll(playerId)
    if not enabled then return 0, 'disabled' end

    if playerId ~= nil then
        playerId = tonumber(playerId)
        if not playerId then return 0, 'invalid_player' end
        local set = byPlayer[playerId]
        if not set then return 0 end

        local ids = {}
        for id in pairs(set) do ids[#ids + 1] = id end
        local removed = 0

        for i = 1, #ids do
            local id = ids[i]
            local entry = waypoints[id]
            if entry then
                if entry.target == playerId then
                    TriggerClientEvent('DTlib:waypoint:remove', playerId, id)
                    waypoints[id] = nil
                    untrackPlayer(playerId, id)
                    removed = removed + 1
                elseif type(entry.target) == 'table' then
                    local newTargets = {}
                    local matched = false
                    for j = 1, #entry.target do
                        if tonumber(entry.target[j]) == playerId then
                            matched = true
                        else
                            newTargets[#newTargets + 1] = entry.target[j]
                        end
                    end
                    if matched then
                        TriggerClientEvent('DTlib:waypoint:remove', playerId, id)
                        entry.target = newTargets
                        untrackPlayer(playerId, id)
                        if #newTargets == 0 then waypoints[id] = nil end
                        removed = removed + 1
                    end
                end
                -- Global (-1) waypoints are intentionally preserved for this player.
                -- They remain part of the shared server state and are not player-owned.
            end
        end
        return removed
    end

    local ids = {}
    for id in pairs(waypoints) do ids[#ids + 1] = id end
    for i = 1, #ids do DT.Waypoint.Remove(ids[i]) end
    byPlayer = {}
    return #ids
end

function DT.Waypoint.RemoveForPlayer(playerId)
    if not enabled then return 0, 'disabled' end
    return DT.Waypoint.RemoveAll(playerId)
end

function DT.Waypoint.Get(id)
    return waypoints[tonumber(id)]
end

function DT.Waypoint.GetAll()
    return waypoints
end

function DT.Waypoint.GetForPlayer(playerId)
    playerId = tonumber(playerId)
    local result = {}
    if not playerId then return result end
    for id, entry in pairs(waypoints) do
        if targetContains(entry.target, playerId) then result[id] = entry end
    end
    return result
end

exports('CreateWaypoint', function(target, data) return DT.Waypoint.Create(target, data) end)
exports('UpdateWaypoint', function(id, data) return DT.Waypoint.Update(id, data) end)
exports('RemoveWaypoint', function(id) return DT.Waypoint.Remove(id) end)
exports('RemoveAllWaypoints', function(playerId) return DT.Waypoint.RemoveAll(playerId) end)
exports('GetWaypoint', function(id) return DT.Waypoint.Get(id) end)
exports('GetWaypoints', function() return DT.Waypoint.GetAll() end)
exports('GetPlayerWaypoints', function(playerId) return DT.Waypoint.GetForPlayer(playerId) end)

if not enabled then
    if DT.Logger and DT.Logger.Info then DT.Logger.Info('WAYPOINT', 'Waypoint module disabled by config.') end
    return
end

RegisterNetEvent('DTlib:waypoint:requestSync', function()
    local src = source
    if DT.Security and DT.Security.RateLimit then
        local allowed = DT.Security.RateLimit(src, 'waypoint_sync', 3, 10000)
        if not allowed then return end
    end
    local current = DT.Waypoint.GetForPlayer(src)
    for id, entry in pairs(current) do
        TriggerClientEvent('DTlib:waypoint:create', src, id, entry.data)
        trackPlayer(src, id)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    local set = byPlayer[src]
    if not set then return end

    local ids = {}
    for id in pairs(set) do ids[#ids + 1] = id end
    for i = 1, #ids do
        local id = ids[i]
        local entry = waypoints[id]
        if entry then
            if entry.target == src then
                waypoints[id] = nil
            elseif type(entry.target) == 'table' then
                local updated = {}
                for j = 1, #entry.target do
                    if tonumber(entry.target[j]) ~= src then updated[#updated + 1] = entry.target[j] end
                end
                entry.target = updated
                if #updated == 0 then waypoints[id] = nil end
            end
        end
    end
    byPlayer[src] = nil
end)

if DT.Logger and DT.Logger.Info then
    DT.Logger.Info('WAYPOINT', 'DT Waypoint module ready.', {
        mapSync = config.syncMapWaypoint == true,
        maxVisible = config.rendering and config.rendering.maxVisible or 18
    })
end
