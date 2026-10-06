local buckets = {}

function DT.Security.ValidateSource(source)
    return type(source) == 'number' and source > 0 and GetPlayerName(source) ~= nil
end

function DT.Security.IsAdmin(source, ace)
    if source == 0 then return true end
    if ace then return IsPlayerAceAllowed(source, ace) end
    local security=DTConfig.Security or {}
    return IsPlayerAceAllowed(source, security.adminAce or 'admin') or IsPlayerAceAllowed(source, security.godAce or 'god')
end

function DT.Security.RateLimit(source, key, maxCalls, windowMs)
    if not DT.Security.ValidateSource(source) then return false, 'invalid_source' end
    key = tostring(key or 'default')
    maxCalls = tonumber(maxCalls) or DTConfig.Security.defaultMaxCalls
    windowMs = tonumber(windowMs) or DTConfig.Security.defaultWindowMs

    local now = GetGameTimer()
    local sourceBucket = buckets[source] or {}
    buckets[source] = sourceBucket
    local entry = sourceBucket[key]

    if not entry or now >= entry.resetAt then
        sourceBucket[key] = {count = 1, resetAt = now + windowMs}
        return true
    end

    entry.count = entry.count + 1
    if entry.count > maxCalls then return false, entry.resetAt - now end
    return true
end

function DT.Security.RequireAdmin(source, ace)
    if DT.Security.IsAdmin(source, ace) then return true end
    TriggerClientEvent('DTlib:client:notify', source, {title = 'DT SECURITY', description = 'You do not have permission.', type = 'error'})
    return false
end

AddEventHandler('playerDropped', function()
    buckets[source] = nil
end)
