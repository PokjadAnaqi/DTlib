local zones = {}
local nextId = 0

local function pointInPolygon(point, points)
    local inside = false
    local j = #points
    for i = 1, #points do
        local xi, yi = points[i].x, points[i].y
        local xj, yj = points[j].x, points[j].y
        local intersects = ((yi > point.y) ~= (yj > point.y)) and
            (point.x < (xj - xi) * (point.y - yi) / ((yj - yi) == 0 and 0.000001 or (yj - yi)) + xi)
        if intersects then inside = not inside end
        j = i
    end
    return inside
end

local function rotatePoint(px, py, cx, cy, angle)
    local rad = math.rad(-angle)
    local cosA, sinA = math.cos(rad), math.sin(rad)
    local dx, dy = px - cx, py - cy
    return dx * cosA - dy * sinA, dx * sinA + dy * cosA
end

local function contains(zone, coords)
    if zone.type == 'sphere' then
        return #(coords - zone.coords) <= zone.radius
    elseif zone.type == 'box' then
        local x, y = rotatePoint(coords.x, coords.y, zone.coords.x, zone.coords.y, zone.rotation or 0.0)
        return math.abs(x) <= zone.size.x * 0.5 and math.abs(y) <= zone.size.y * 0.5 and math.abs(coords.z - zone.coords.z) <= zone.size.z * 0.5
    elseif zone.type == 'poly' then
        if math.abs(coords.z - zone.z) > zone.thickness * 0.5 then return false end
        return pointInPolygon(coords, zone.points)
    end
    return false
end

local function createZone(zone)
    nextId = nextId + 1
    zone.id = nextId
    zone.inside = false
    zones[zone.id] = zone
    return zone.id
end

function DT.Zone.Sphere(data)
    assert(data and data.coords, 'DT.Zone.Sphere: coords is required')
    return createZone({
        type = 'sphere', coords = data.coords, radius = data.radius or 1.5,
        onEnter = data.onEnter, onExit = data.onExit, insideCb = data.inside,
        interval = data.interval or 250, lastTick = 0
    })
end

function DT.Zone.Box(data)
    assert(data and data.coords, 'DT.Zone.Box: coords is required')
    return createZone({
        type = 'box', coords = data.coords, size = data.size or vector3(1.0, 1.0, 1.0), rotation = data.rotation or 0.0,
        onEnter = data.onEnter, onExit = data.onExit, insideCb = data.inside,
        interval = data.interval or 250, lastTick = 0
    })
end

function DT.Zone.Poly(data)
    assert(data and data.points and #data.points >= 3, 'DT.Zone.Poly: at least 3 points are required')
    local z = data.z or data.points[1].z or 0.0
    return createZone({
        type = 'poly', points = data.points, z = z, thickness = data.thickness or 4.0,
        onEnter = data.onEnter, onExit = data.onExit, insideCb = data.inside,
        interval = data.interval or 250, lastTick = 0
    })
end

function DT.Zone.Remove(id)
    zones[id] = nil
end

CreateThread(function()
    while true do
        local sleep = next(zones) and 100 or 1000
        local now = GetGameTimer()
        local coords = GetEntityCoords(PlayerPedId())

        for _, zone in pairs(zones) do
            if now - zone.lastTick >= zone.interval then
                zone.lastTick = now
                local isInside = contains(zone, coords)
                if isInside and not zone.inside then
                    zone.inside = true
                    if zone.onEnter then zone.onEnter(zone.id) end
                elseif not isInside and zone.inside then
                    zone.inside = false
                    if zone.onExit then zone.onExit(zone.id) end
                end
                if isInside and zone.insideCb then zone.insideCb(zone.id) end
            end
        end
        Wait(sleep)
    end
end)
