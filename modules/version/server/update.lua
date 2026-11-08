-- One GitHub request for DTlib, never one request per consumer.
DT.Update = DT.Update or {}
local update = DT.Update
local url = 'https://api.github.com/repos/PokjadAnaqi/DTlib/releases/latest'
local download = 'https://github.com/PokjadAnaqi/DTlib/releases/latest'
local busy = false
local sequence = 0
local lastPrinted, etag, cached
local function config()
    return DTConfig.UpdateCheck or {}
end
local function parse(value)
    if type(value) ~= 'string' then
        return nil
    end
    value = value:gsub('^v', ''):gsub('%+[%w%.%-]+$', '')
    local base, pre = value:match('^(%d+%.%d+%.%d+)%-([%w%.%-]+)$')
    base = base or value
    local major, minor, patch = base:match('^(%d+)%.(%d+)%.(%d+)$')
    if not major then
        return nil
    end
    local result = { tonumber(major), tonumber(minor), tonumber(patch), pre = pre }
    for _, part in ipairs({ major, minor, patch }) do
        if #part > 1 and part:sub(1, 1) == '0' then
            return nil
        end
    end
    if pre then
        if pre:sub(1, 1) == '.' or pre:sub(-1) == '.' or pre:find('..', 1, true) then
            return nil
        end
        result.ids = {}
        for id in pre:gmatch('[^.]+') do
            if id:match('^%d+$') and #id > 1 and id:sub(1, 1) == '0' then
                return nil
            end
            result.ids[#result.ids + 1] = id
        end
    end
    return result
end
function update.Compare(leftVersion, rightVersion)
    leftVersion, rightVersion = parse(leftVersion), parse(rightVersion)
    if not leftVersion or not rightVersion then
        return nil, 'invalid_version'
    end
    for index = 1, 3 do
        if leftVersion[index] ~= rightVersion[index] then
            return leftVersion[index] < rightVersion[index] and -1 or 1
        end
    end
    if leftVersion.pre == rightVersion.pre then
        return 0
    end
    if not leftVersion.pre then
        return 1
    end
    if not rightVersion.pre then
        return -1
    end
    for index = 1, math.max(#leftVersion.ids, #rightVersion.ids) do
        local x, y = leftVersion.ids[index], rightVersion.ids[index]
        if not x then
            return -1
        end
        if not y then
            return 1
        end
        if x ~= y then
            local leftNumber = x:match('^%d+$') and tonumber(x)
            local rightNumber = y:match('^%d+$') and tonumber(y)
            if leftNumber and rightNumber then
                return leftNumber < rightNumber and -1 or 1
            end
            if leftNumber then
                return -1
            end
            if rightNumber then
                return 1
            end
            return x < y and -1 or 1
        end
    end
    return 0
end
local function usesDTlib(resource)
    if not GetNumResourceMetadata then
        return false
    end
    for _, key in ipairs({ 'dependency', 'shared_script', 'server_script', 'client_script' }) do
        for index = 0, (GetNumResourceMetadata(resource, key) or 0) - 1 do
            local value = tostring(GetResourceMetadata(resource, key, index) or ''):lower()
            if (key == 'dependency' and value == 'dtlib') or value:match('^@dtlib/') then
                return true
            end
        end
    end
    return false
end
function update.ListConsumers()
    local out = {}
    if not GetNumResources or not GetResourceByFindIndex then
        return out
    end
    for index = 0, GetNumResources() - 1 do
        local name = GetResourceByFindIndex(index)
        if name and name ~= GetCurrentResourceName() then
            local state = GetResourceState(name)
            if (state == 'started' or state == 'starting' or config().includeStopped == true) and usesDTlib(name) then
                out[#out + 1] = { name = name, version = GetResourceMetadata(name, 'version', 0), state = state }
            end
        end
    end
    table.sort(out, function(left, right)
        return left.name:lower() < right.name:lower()
    end)
    return out
end
local function report(latest)
    local installed = DT.Version or GetResourceMetadata(GetCurrentResourceName(), 'version', 0)
    local comparison = update.Compare(installed, latest)
    if comparison == nil then
        return false, 'invalid_version'
    end
    local key = tostring(installed) .. ':' .. latest
    if key == lastPrinted then
        return true
    end
    lastPrinted = key

    local message
    if comparison < 0 then
        message = ('Update available | %s → %s | %s'):format(installed, latest, download)
    elseif config().logUpToDate == false then
        return true
    elseif comparison == 0 then
        message = ('Up to date | %s'):format(installed)
    else
        message = ('Installed %s | latest official %s'):format(installed, latest)
    end

    if config().listConsumers ~= false then
        local consumers = update.ListConsumers()
        message = ('%s | %d consumers'):format(message, #consumers)
        if DTConfig.Debug and DT.Logger and DT.Logger.Debug and #consumers > 0 then
            local names = {}
            for index, consumer in ipairs(consumers) do
                names[index] = consumer.name
            end
            DT.Logger.Debug('UPDATE', 'Consumers: ' .. table.concat(names, ', '))
        end
    end
    if DT.Logger and DT.Logger.Info then
        DT.Logger.Info('UPDATE', message)
    end
    return true
end
function update.Check()
    if config().enabled == false then
        return false, 'disabled'
    end
    if busy then
        return false, 'busy'
    end
    busy = true
    sequence = sequence + 1
    local current = sequence
    SetTimeout(10000, function()
        if current == sequence then
            busy = false
            sequence = sequence + 1
        end
    end)
    local headers = { ['Accept'] = 'application/vnd.github+json', ['User-Agent'] = 'DTlib-UpdateChecker' }
    if etag then
        headers['If-None-Match'] = etag
    end
    local ok = pcall(PerformHttpRequest, url, function(status, body, responseHeaders)
        if current ~= sequence then
            return
        end
        busy = false
        sequence = sequence + 1
        if status == 304 and cached then
            report(cached)
            return
        end
        if status ~= 200 then
            return
        end
        local decoded, data = pcall(json.decode, body or '')
        if
            not decoded
            or type(data) ~= 'table'
            or data.draft == true
            or data.prerelease == true
            or not parse(data.tag_name)
        then
            return
        end
        cached = data.tag_name
        etag = type(responseHeaders) == 'table' and (responseHeaders.ETag or responseHeaders.etag) or nil
        report(cached)
    end, 'GET', '', headers)
    if not ok then
        busy = false
        sequence = sequence + 1
        return false, 'request_failed'
    end
    return true
end
exports('CheckForUpdates', update.Check)
exports('GetDTlibConsumers', update.ListConsumers)
CreateThread(function()
    Wait(5000)
    while config().enabled ~= false do
        update.Check()
        local minutes = tonumber(config().intervalMinutes) or 60
        if minutes ~= minutes then
            minutes = 60
        end
        Wait(math.floor(math.max(5, math.min(1440, minutes))) * 60000)
    end
end)
