local config = DTConfig.Waypoint or {}

DT.Waypoint = DT.Waypoint or {}

local enabled = config.enabled == true
local localWaypoints = {}
local waypointArray = {}
local waypointIndex = {}
local nextWaypointId = 0
local serverToClient = {}
local renderList = {}
local renderingSet = {}
local mapWaypointId = nil
local mapWaypointLastCoords = nil
local mapSyncEnabled = config.syncMapWaypoint == true

local poolAvailable = {}
local poolInUse = {}
local poolCreated = 0
local duiReady = {}

local resourceName = GetCurrentResourceName()

-- DUI callbacks are diagnostic only. Rendering never depends on this callback
-- because some FiveM/CEF builds can delay or drop DUI -> NUI callbacks.
RegisterNUICallback('dtlib_waypoint_ready', function(data, cb)
    local id = tonumber(data and data.id)
    if id then duiReady[id] = true end
    cb({ ok = true })
end)

local function log(level, message, data)
    if not DT.Logger then return end
    local fn = DT.Logger[level]
    if type(fn) == 'function' then
        fn('WAYPOINT', message, data)
    end
end

local function toVec3(value)
    if type(value) == 'vector3' then return value end
    if type(value) == 'vector4' then return vec3(value.x, value.y, value.z) end
    if type(value) ~= 'table' then return nil end
    local x = tonumber(value.x or value[1])
    local y = tonumber(value.y or value[2])
    local z = tonumber(value.z or value[3])
    if not x or not y or not z then return nil end
    return vec3(x, y, z)
end

local function copyTable(input)
    if type(input) ~= 'table' then return input end
    local output = {}
    for key, value in pairs(input) do
        output[key] = type(value) == 'table' and copyTable(value) or value
    end
    return output
end

local function distanceSquared(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

local function resolveMapWaypointZ(value)
    local coords = toVec3(value)
    if not coords then return nil end

    -- GTA map waypoints commonly report Z=0. Probe ground height without
    -- blocking the renderer. If collision is not streamed yet, use a sane
    -- fallback height and keep updating on subsequent map-sync ticks.
    RequestCollisionAtCoord(coords.x, coords.y, 1000.0)

    local probes = { 1000.0, 750.0, 500.0, 250.0, 100.0, 50.0 }
    for i = 1, #probes do
        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, probes[i], false)
        if found then
            return vec3(coords.x, coords.y, groundZ)
        end
    end

    if math.abs(coords.z) > 1.0 then
        return coords
    end

    local ped = PlayerPedId()
    local player = ped and ped ~= 0 and GetEntityCoords(ped) or vec3(coords.x, coords.y, 30.0)
    return vec3(coords.x, coords.y, player.z)
end

local function normalizeData(input, previous)
    input = type(input) == 'table' and input or {}
    previous = previous or {}

    local coords = input.coords ~= nil and toVec3(input.coords) or previous.coords
    if not coords then return nil, 'invalid_coords' end

    local defaults = config.defaults or {}
    local drawDistance = tonumber(input.drawDistance or previous.drawDistance or defaults.drawDistance) or 500.0
    local fadeDistance = tonumber(input.fadeDistance or previous.fadeDistance or defaults.fadeDistance) or math.max(0.0, drawDistance - 100.0)
    fadeDistance = math.min(fadeDistance, drawDistance)

    local removeDistance = input.removeDistance
    if removeDistance == nil then removeDistance = previous.removeDistance end
    removeDistance = tonumber(removeDistance)

    local displayDistance = input.displayDistance
    if displayDistance == nil then displayDistance = previous.displayDistance end
    if displayDistance == nil then displayDistance = defaults.displayDistance ~= false end

    local data = {
        coords = coords,
        type = tostring(input.type or previous.type or defaults.type or 'objective'),
        label = tostring(input.label or previous.label or defaults.label or 'OBJECTIVE'),
        subtitle = tostring(input.subtitle or previous.subtitle or defaults.subtitle or 'DT NAVIGATION'),
        color = tostring(input.color or previous.color or defaults.color or '#9db34f'),
        icon = input.icon ~= nil and input.icon or previous.icon or defaults.icon or 'fa-solid fa-location-dot',
        image = input.image ~= nil and input.image or previous.image,
        iconColor = input.iconColor ~= nil and input.iconColor or previous.iconColor,
        size = tonumber(input.size or previous.size or defaults.size) or 1.0,
        drawDistance = drawDistance,
        drawDistanceSq = drawDistance * drawDistance,
        fadeDistance = fadeDistance,
        fadeDistanceSq = fadeDistance * fadeDistance,
        displayDistance = displayDistance == true,
        removeDistance = removeDistance,
        removeDistanceSq = removeDistance and (removeDistance * removeDistance) or nil,
        heightOffset = tonumber(input.heightOffset or previous.heightOffset or defaults.heightOffset) or 1.15,
        minScale = tonumber(input.minScale or previous.minScale or defaults.minScale) or 0.72,
        maxScale = tonumber(input.maxScale or previous.maxScale or defaults.maxScale) or 14.0,
        pulse = (function()
            if input.pulse ~= nil then return input.pulse == true end
            return previous.pulse == true
        end)(),
        owner = input.owner or previous.owner or 'local',
        metadata = input.metadata ~= nil and copyTable(input.metadata) or previous.metadata,
    }

    return data
end

local function waypointMessage(waypoint)
    local data = waypoint.data
    return {
        action = 'configure',
        data = {
            type = data.type,
            label = data.label,
            subtitle = data.subtitle,
            color = data.color,
            icon = data.icon,
            image = data.image,
            iconColor = data.iconColor,
            displayDistance = data.displayDistance,
            pulse = data.pulse,
        }
    }
end

local function destroyDuiWrapper(wrapper)
    if not wrapper then return end
    if wrapper.dui and wrapper.dui ~= 0 then
        SetDuiUrl(wrapper.dui, 'about:blank')
        DestroyDui(wrapper.dui)
    end
    if wrapper.id then
        poolInUse[wrapper.id] = nil
        duiReady[wrapper.id] = nil
    end
end

local function createDuiWrapper()
    poolCreated = poolCreated + 1
    local id = poolCreated
    local width = tonumber(config.dui and config.dui.width) or 512
    local height = tonumber(config.dui and config.dui.height) or 1024

    -- Keep the same resource-local DUI URL form proven by sleepless_waypoints.
    -- Do not gate the renderer on a NUI callback: IsDuiAvailable + a small
    -- warm-up window is more reliable across FiveM/CEF builds.
    local url = ('nui://%s/html/waypoint.html'):format(resourceName)
    local duiObject = CreateDui(url, width, height)
    if not duiObject or duiObject == 0 then
        log('Warn', ('Failed to create waypoint DUI instance #%s'):format(id))
        return nil
    end

    local timeoutMs = tonumber(config.dui and config.dui.readyTimeout) or 5000
    local deadline = GetGameTimer() + timeoutMs
    while not IsDuiAvailable(duiObject) and GetGameTimer() < deadline do
        Wait(25)
    end

    if not IsDuiAvailable(duiObject) then
        log('Warn', ('Waypoint DUI #%s was not available within %sms'):format(id, timeoutMs), { url = url })
        DestroyDui(duiObject)
        return nil
    end

    local duiHandle = GetDuiHandle(duiObject)
    local txdName = ('dtlib_waypoint_txd_%s'):format(id)
    local txnName = ('dtlib_waypoint_txn_%s'):format(id)
    local runtimeTxd = CreateRuntimeTxd(txdName)
    local txdObject = CreateRuntimeTextureFromDuiHandle(runtimeTxd, txnName, duiHandle)

    local wrapper = {
        id = id,
        dui = duiObject,
        duiHandle = duiHandle,
        runtimeTxd = runtimeTxd,
        txdObject = txdObject,
        txd = txdName,
        txn = txnName,
        assigned = nil,
        ready = true,
    }

    poolInUse[id] = wrapper
    duiReady[id] = true

    -- Give the page a short paint window. Configuration is also resent when
    -- assigned, so a late JS listener cannot leave the texture blank.
    Wait(150)
    SendDuiMessage(duiObject, json.encode({ action = 'reset' }))
    return wrapper
end

local function acquireDui(waypoint)
    if waypoint.dui then return true end

    local wrapper
    if #poolAvailable > 0 then
        wrapper = table.remove(poolAvailable)
        if wrapper and wrapper.ready and wrapper.dui and wrapper.dui ~= 0 then
            poolInUse[wrapper.id] = wrapper
        else
            if wrapper then destroyDuiWrapper(wrapper) end
            wrapper = nil
        end
    end

    if not wrapper then
        local maxVisible = tonumber(config.rendering and config.rendering.maxVisible) or 18
        local activeCount = 0
        for _ in pairs(poolInUse) do activeCount = activeCount + 1 end
        if activeCount >= maxVisible then return false end
        wrapper = createDuiWrapper()
    end

    if not wrapper or not wrapper.ready then return false end
    wrapper.assigned = waypoint.id
    waypoint.dui = wrapper
    local message = json.encode(waypointMessage(waypoint))
    SendDuiMessage(wrapper.dui, message)
    -- Resend once after the next frame; harmless if the page was already ready.
    SetTimeout(100, function()
        if waypoint.dui == wrapper and wrapper.dui and wrapper.dui ~= 0 then
            SendDuiMessage(wrapper.dui, message)
        end
    end)
    waypoint.lastDistance = nil
    waypoint.nextDistanceUpdate = 0
    return true
end

local function releaseDui(waypoint)
    local wrapper = waypoint and waypoint.dui
    if not wrapper then return end
    waypoint.dui = nil
    waypoint.lastDistance = nil
    waypoint.nextDistanceUpdate = nil
    wrapper.assigned = nil
    SendDuiMessage(wrapper.dui, json.encode({ action = 'reset' }))
    poolInUse[wrapper.id] = nil
    poolAvailable[#poolAvailable + 1] = wrapper
end

local function destroyDuiPool()
    local seen = {}
    for _, wrapper in pairs(poolInUse) do
        if wrapper and not seen[wrapper] then
            seen[wrapper] = true
            destroyDuiWrapper(wrapper)
        end
    end
    for i = 1, #poolAvailable do
        local wrapper = poolAvailable[i]
        if wrapper and not seen[wrapper] then
            seen[wrapper] = true
            destroyDuiWrapper(wrapper)
        end
    end
    poolAvailable = {}
    poolInUse = {}
    duiReady = {}
    poolCreated = 0
end

local function addWaypoint(data)
    nextWaypointId = nextWaypointId + 1
    local id = nextWaypointId
    local waypoint = {
        id = id,
        data = data,
        dui = nil,
        active = true,
        distanceSq = math.huge,
        lastDistance = nil,
        nextDistanceUpdate = 0,
    }

    waypointArray[#waypointArray + 1] = waypoint
    waypointIndex[id] = #waypointArray
    localWaypoints[id] = waypoint
    return id
end

local function removeWaypoint(id)
    local waypoint = localWaypoints[id]
    if not waypoint then return false end
    waypoint.active = false
    releaseDui(waypoint)

    local index = waypointIndex[id]
    local lastIndex = #waypointArray
    if index and index ~= lastIndex then
        local last = waypointArray[lastIndex]
        waypointArray[index] = last
        waypointIndex[last.id] = index
    end
    waypointArray[lastIndex] = nil
    waypointIndex[id] = nil
    localWaypoints[id] = nil
    renderingSet[id] = nil

    for serverId, clientId in pairs(serverToClient) do
        if clientId == id then serverToClient[serverId] = nil end
    end
    if mapWaypointId == id then mapWaypointId = nil end
    return true
end

local function updateWaypoint(id, patch)
    local waypoint = localWaypoints[id]
    if not waypoint then return false, 'not_found' end
    local data, err = normalizeData(patch, waypoint.data)
    if not data then return false, err end
    waypoint.data = data
    if waypoint.dui then
        SendDuiMessage(waypoint.dui.dui, json.encode(waypointMessage(waypoint)))
    end
    return true
end

local function normalizeRightVector(pos, camPos)
    local dx = camPos.x - pos.x
    local dy = camPos.y - pos.y
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 0.001 then return 1.0, 0.0 end
    dx, dy = dx / length, dy / length
    -- Equivalent to cross(up, forward) in the reference implementation.
    return -dy, dx
end

local function getRenderDimensions(waypoint, camPos)
    local data = waypoint.data
    local distSq = distanceSquared(camPos, data.coords)
    waypoint.distanceSq = distSq
    local dist = math.sqrt(math.max(distSq, 0.001))
    local rendering = config.rendering or {}
    local divisor = tonumber(rendering.perspectiveDivisor) or 20.0
    local perspective = math.max(data.minScale, math.min(data.maxScale, dist / divisor))
    local baseWidth = tonumber(rendering.baseWidth) or 1.18
    local baseHeight = tonumber(rendering.baseHeight) or 1.78
    return baseWidth * data.size * perspective, baseHeight * data.size * perspective
end

local function anyCornerOnScreen(center, width, height, camPos)
    local rx, ry = normalizeRightVector(center, camPos)
    local halfWidth = width * 0.5
    local halfHeight = height * 0.5
    local points = {
        center,
        vec3(center.x - rx * halfWidth, center.y - ry * halfWidth, center.z + halfHeight),
        vec3(center.x + rx * halfWidth, center.y + ry * halfWidth, center.z + halfHeight),
        vec3(center.x - rx * halfWidth, center.y - ry * halfWidth, center.z - halfHeight),
        vec3(center.x + rx * halfWidth, center.y + ry * halfWidth, center.z - halfHeight),
    }
    for i = 1, #points do
        local p = points[i]
        local visible = GetScreenCoordFromWorldCoord(p.x, p.y, p.z)
        if visible == true or visible == 1 then return true end
    end
    return false
end

local function drawPolyBothSides(a, b, c, r, g, bcol, alpha, txd, txn, au, av, bu, bv, cu, cv)
    DrawTexturedPoly(
        a.x, a.y, a.z,
        b.x, b.y, b.z,
        c.x, c.y, c.z,
        r, g, bcol, alpha,
        txd, txn,
        au, av, 0.0,
        bu, bv, 0.0,
        cu, cv, 0.0
    )
    -- Draw reverse winding too. DrawTexturedPoly is back-face culled and camera
    -- orientation can flip around steep pitch/near-vertical angles.
    DrawTexturedPoly(
        c.x, c.y, c.z,
        b.x, b.y, b.z,
        a.x, a.y, a.z,
        r, g, bcol, alpha,
        txd, txn,
        cu, cv, 0.0,
        bu, bv, 0.0,
        au, av, 0.0
    )
end

local function drawBillboard(waypoint, camPos, alpha)
    local wrapper = waypoint.dui
    if not wrapper or not wrapper.ready then return false end

    local data = waypoint.data
    local width, height = getRenderDimensions(waypoint, camPos)
    local center = vec3(data.coords.x, data.coords.y, data.coords.z + data.heightOffset + (height * 0.5))
    local rx, ry = normalizeRightVector(center, camPos)
    local halfWidth = width * 0.5
    local halfHeight = height * 0.5

    local tl = vec3(center.x - rx * halfWidth, center.y - ry * halfWidth, center.z + halfHeight)
    local tr = vec3(center.x + rx * halfWidth, center.y + ry * halfWidth, center.z + halfHeight)
    local bl = vec3(center.x - rx * halfWidth, center.y - ry * halfWidth, center.z - halfHeight)
    local br = vec3(center.x + rx * halfWidth, center.y + ry * halfWidth, center.z - halfHeight)

    drawPolyBothSides(tr, tl, bl, 255, 255, 255, alpha, wrapper.txd, wrapper.txn, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0)
    drawPolyBothSides(bl, br, tr, 255, 255, 255, alpha, wrapper.txd, wrapper.txn, 0.0, 1.0, 1.0, 1.0, 1.0, 0.0)
    return true
end

local function drawSpriteWaypoint(waypoint, camPos, alpha)
    local wrapper = waypoint.dui
    if not wrapper or not wrapper.ready then return false end

    local data = waypoint.data
    local anchor = vec3(data.coords.x, data.coords.y, data.coords.z + data.heightOffset)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(anchor.x, anchor.y, anchor.z)
    if not onScreen then return false end

    local dist = math.sqrt(math.max(distanceSquared(camPos, data.coords), 0.001))
    local rendering = config.rendering or {}
    local baseWidth = tonumber(rendering.spriteWidth) or 0.115
    local minFactor = tonumber(rendering.spriteMinFactor) or 0.72
    local maxFactor = tonumber(rendering.spriteMaxFactor) or 1.0
    local factor = 1.0 - math.min(1.0, dist / math.max(1.0, data.drawDistance)) * (1.0 - minFactor)
    factor = math.max(minFactor, math.min(maxFactor, factor))

    local aspect = GetAspectRatio(false)
    if not aspect or aspect <= 0.0 then aspect = 16.0 / 9.0 end
    local width = baseWidth * data.size * factor
    local height = width * 2.0 * aspect

    -- waypoint.html places the locator point at the bottom of the 512x1024
    -- canvas, so shift the sprite upward and anchor its bottom to the 3D point.
    local centerY = screenY - (height * 0.5)
    DrawSprite(wrapper.txd, wrapper.txn, screenX, centerY, width, height, 0.0, 255, 255, 255, alpha)
    return true
end

local function drawNativeFallback(waypoint, playerPos)
    local fallback = config.fallback or {}
    if fallback.enabled == false then return end
    local data = waypoint.data
    local distance = math.sqrt(distanceSquared(playerPos, data.coords))
    local scale = math.max(0.22, math.min(0.7, 0.65 - (distance / 1200.0)))
    DrawMarker(
        tonumber(fallback.markerType) or 28,
        data.coords.x, data.coords.y, data.coords.z + 0.45,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        scale, scale, scale,
        tonumber(fallback.r) or 157,
        tonumber(fallback.g) or 179,
        tonumber(fallback.b) or 79,
        tonumber(fallback.a) or 190,
        false, true, 2, false, nil, nil, false
    )
end

local function shouldRender(waypoint, camPos)
    local data = waypoint.data
    local distSq = distanceSquared(camPos, data.coords)
    waypoint.distanceSq = distSq
    if distSq > data.drawDistanceSq then return false end

    local width, height = getRenderDimensions(waypoint, camPos)
    local center = vec3(data.coords.x, data.coords.y, data.coords.z + data.heightOffset + (height * 0.5))
    return anyCornerOnScreen(center, width, height, camPos)
end

local function calculateAlpha(waypoint)
    local data = waypoint.data
    if waypoint.distanceSq <= data.fadeDistanceSq then return 255 end
    local distance = math.sqrt(waypoint.distanceSq)
    local span = math.max(1.0, data.drawDistance - data.fadeDistance)
    local t = math.min(1.0, math.max(0.0, (distance - data.fadeDistance) / span))
    return math.floor(255 * (1.0 - t))
end

function DT.Waypoint.Enabled()
    return enabled
end

function DT.Waypoint.Create(input)
    if not enabled then return nil, 'disabled' end
    local data, err = normalizeData(input)
    if not data then return nil, err end
    data.owner = input and input.owner or 'local'
    return addWaypoint(data)
end

function DT.Waypoint.Update(id, patch)
    if not enabled then return false, 'disabled' end
    return updateWaypoint(tonumber(id), patch)
end

function DT.Waypoint.Remove(id)
    if not enabled then return false, 'disabled' end
    return removeWaypoint(tonumber(id))
end

function DT.Waypoint.RemoveAll(owner)
    if not enabled then return 0, 'disabled' end
    owner = owner or 'local'
    local ids = {}
    for id, waypoint in pairs(localWaypoints) do
        if owner == '*' or waypoint.data.owner == owner then ids[#ids + 1] = id end
    end
    for i = 1, #ids do removeWaypoint(ids[i]) end
    return #ids
end

function DT.Waypoint.Get(id)
    return localWaypoints[tonumber(id)]
end

function DT.Waypoint.GetAll()
    return localWaypoints
end

function DT.Waypoint.SetMapSync(state)
    mapSyncEnabled = state == true and enabled
    if not mapSyncEnabled and mapWaypointId then
        removeWaypoint(mapWaypointId)
        mapWaypointId = nil
        mapWaypointLastCoords = nil
    end
    return mapSyncEnabled
end

function DT.Waypoint.GetMapSync()
    return mapSyncEnabled
end

exports('CreateWaypoint', function(data) return DT.Waypoint.Create(data) end)
exports('UpdateWaypoint', function(id, data) return DT.Waypoint.Update(id, data) end)
exports('RemoveWaypoint', function(id) return DT.Waypoint.Remove(id) end)
exports('RemoveAllWaypoints', function(owner) return DT.Waypoint.RemoveAll(owner) end)
exports('GetWaypoint', function(id) return DT.Waypoint.Get(id) end)
exports('GetWaypoints', function() return DT.Waypoint.GetAll() end)
exports('SetWaypointMapSync', function(state) return DT.Waypoint.SetMapSync(state) end)

if not enabled then
    CreateThread(function()
        Wait(0)
        if DTConfig.Debug then print('[DTlib] Waypoint module disabled by config.') end
    end)
    return
end

RegisterNetEvent('DTlib:waypoint:create', function(serverId, data)
    serverId = tonumber(serverId)
    if not serverId then return end
    local current = serverToClient[serverId]
    if current then removeWaypoint(current) end
    data = type(data) == 'table' and data or {}
    data.owner = 'server'
    local clientId = DT.Waypoint.Create(data)
    if clientId then serverToClient[serverId] = clientId end
end)

RegisterNetEvent('DTlib:waypoint:update', function(serverId, patch)
    local clientId = serverToClient[tonumber(serverId)]
    if clientId then DT.Waypoint.Update(clientId, patch) end
end)

RegisterNetEvent('DTlib:waypoint:remove', function(serverId)
    local key = tonumber(serverId)
    local clientId = serverToClient[key]
    if not clientId then return end
    removeWaypoint(clientId)
    serverToClient[key] = nil
end)

RegisterNetEvent('DTlib:waypoint:removeAllServer', function()
    local ids = {}
    for serverId, clientId in pairs(serverToClient) do
        ids[#ids + 1] = { serverId = serverId, clientId = clientId }
    end
    for i = 1, #ids do
        removeWaypoint(ids[i].clientId)
        serverToClient[ids[i].serverId] = nil
    end
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent('DTlib:waypoint:requestSync')
end)

CreateThread(function()
    local updateInterval = tonumber(config.rendering and config.rendering.updateInterval) or 150
    local maxVisible = tonumber(config.rendering and config.rendering.maxVisible) or 18

    while enabled do
        if #waypointArray == 0 then
            Wait(500)
        else
            local camPos = GetFinalRenderedCamCoord()
            local candidates = {}
            local newSet = {}

            for i = 1, #waypointArray do
                local waypoint = waypointArray[i]
                if waypoint and waypoint.active and shouldRender(waypoint, camPos) then
                    candidates[#candidates + 1] = waypoint
                end
            end

            table.sort(candidates, function(a, b) return a.distanceSq < b.distanceSq end)

            local newRenderList = {}
            local count = math.min(#candidates, maxVisible)
            for i = 1, count do
                local waypoint = candidates[i]
                acquireDui(waypoint)
                newRenderList[#newRenderList + 1] = waypoint
                newSet[waypoint.id] = true
            end

            for id in pairs(renderingSet) do
                if not newSet[id] then
                    local waypoint = localWaypoints[id]
                    if waypoint then releaseDui(waypoint) end
                end
            end

            renderingSet = newSet
            renderList = newRenderList
            Wait(updateInterval)
        end
    end
end)

CreateThread(function()
    local distanceUpdateInterval = tonumber(config.rendering and config.rendering.distanceUpdateInterval) or 250
    while enabled do
        if #renderList == 0 then
            Wait(125)
        else
            local playerPos = GetEntityCoords(PlayerPedId())
            local camPos = GetFinalRenderedCamCoord()
            local now = GetGameTimer()

            for i = #renderList, 1, -1 do
                local waypoint = renderList[i]
                if waypoint and waypoint.active then
                    local playerDistSq = distanceSquared(playerPos, waypoint.data.coords)
                    if waypoint.data.removeDistanceSq and playerDistSq <= waypoint.data.removeDistanceSq then
                        removeWaypoint(waypoint.id)
                    else
                        if waypoint.dui and waypoint.data.displayDistance and now >= (waypoint.nextDistanceUpdate or 0) then
                            local distance = math.floor(math.sqrt(playerDistSq) + 0.5)
                            if distance ~= waypoint.lastDistance then
                                waypoint.lastDistance = distance
                                SendDuiMessage(waypoint.dui.dui, json.encode({
                                    action = 'distance',
                                    value = distance
                                }))
                            end
                            waypoint.nextDistanceUpdate = now + distanceUpdateInterval
                        end

                        local alpha = calculateAlpha(waypoint)
                        local renderMode = tostring((config.rendering and config.rendering.mode) or 'sprite'):lower()
                        local rendered
                        if waypoint.dui then
                            if renderMode == 'world' or renderMode == 'poly' then
                                rendered = drawBillboard(waypoint, camPos, alpha)
                            else
                                rendered = drawSpriteWaypoint(waypoint, camPos, alpha)
                            end
                        end
                        if not rendered then drawNativeFallback(waypoint, playerPos) end
                    end
                end
            end
            Wait(0)
        end
    end
end)

CreateThread(function()
    local mapCfg = config.mapWaypoint or {}
    local checkInterval = tonumber(mapCfg.updateInterval) or 500
    local moveThresholdSq = (tonumber(mapCfg.moveThreshold) or 2.0) ^ 2

    while enabled do
        if mapSyncEnabled then
            if IsWaypointActive() then
                local blip = GetFirstBlipInfoId(8)
                if blip and blip ~= 0 then
                    local coords = resolveMapWaypointZ(GetBlipInfoIdCoord(blip))
                    if not coords then
                        Wait(checkInterval)
                        goto continue_map_waypoint
                    end
                    if not mapWaypointId then
                        local data = copyTable(mapCfg)
                        data.coords = coords
                        data.owner = 'map'
                        data.updateInterval = nil
                        data.moveThreshold = nil
                        mapWaypointId = DT.Waypoint.Create(data)
                        mapWaypointLastCoords = coords
                    elseif not mapWaypointLastCoords or distanceSquared(coords, mapWaypointLastCoords) >= moveThresholdSq then
                        DT.Waypoint.Update(mapWaypointId, { coords = coords })
                        mapWaypointLastCoords = coords
                    end
                end
            elseif mapWaypointId then
                removeWaypoint(mapWaypointId)
                mapWaypointId = nil
                mapWaypointLastCoords = nil
            end
        end
        ::continue_map_waypoint::
        Wait(checkInterval)
    end
end)

RegisterCommand('dtlib:waypoint:test', function()
    if not enabled then
        print('[DTlib] Waypoint test unavailable: module is disabled.')
        return
    end

    local ped = PlayerPedId()
    local p = GetEntityCoords(ped)
    local f = GetEntityForwardVector(ped)
    local coords = vec3(p.x + (f.x * 8.0), p.y + (f.y * 8.0), p.z)

    local id, err = DT.Waypoint.Create({
        coords = coords,
        type = 'objective',
        label = 'DT WAYPOINT TEST',
        subtitle = 'RENDER DIAGNOSTIC',
        icon = 'fa-solid fa-location-dot',
        color = '#9db34f',
        displayDistance = true,
        pulse = true,
        drawDistance = 100.0,
        fadeDistance = 80.0,
        removeDistance = 1.5
    })

    if id then
        print(('[DTlib] Waypoint test created: id=%s | coords=%.2f, %.2f, %.2f | enabled=%s'):format(id, coords.x, coords.y, coords.z, tostring(enabled)))
    else
        print(('[DTlib] Waypoint test failed: %s'):format(tostring(err)))
    end
end, false)

RegisterCommand('dtlib:waypoint:dui', function()
    if not enabled then
        print('[DTlib] Waypoint DUI diagnostic unavailable: module disabled.')
        return
    end

    local wrapper = createDuiWrapper()
    if not wrapper then
        print('[DTlib] Waypoint DUI diagnostic FAILED: CreateDui/IsDuiAvailable failed.')
        return
    end

    SendDuiMessage(wrapper.dui, json.encode({
        action = 'configure',
        data = {
            type = 'objective',
            label = 'DUI ONLINE',
            subtitle = 'DT WAYPOINT DIAGNOSTIC',
            color = '#9db34f',
            icon = 'fa-solid fa-location-dot',
            displayDistance = true,
            pulse = true,
        }
    }))
    SendDuiMessage(wrapper.dui, json.encode({ action = 'distance', value = 14 }))

    CreateThread(function()
        local expires = GetGameTimer() + 8000
        while GetGameTimer() < expires do
            local aspect = GetAspectRatio(false)
            if not aspect or aspect <= 0.0 then aspect = 16.0 / 9.0 end
            local width = 0.14
            local height = width * 2.0 * aspect
            DrawSprite(wrapper.txd, wrapper.txn, 0.50, 0.50, width, height, 0.0, 255, 255, 255, 255)
            Wait(0)
        end
        destroyDuiWrapper(wrapper)
    end)

    print('[DTlib] Waypoint DUI diagnostic started for 8 seconds at screen center.')
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= resourceName then return end
    local ids = {}
    for id in pairs(localWaypoints) do ids[#ids + 1] = id end
    for i = 1, #ids do removeWaypoint(ids[i]) end
    destroyDuiPool()
end)
