local colours = {
    INFO = '^2',
    WARN = '^3',
    ERROR = '^1',
    AUDIT = '^5',
    DEBUG = '^6'
}

local watchedResources = {
    qbx_core = 'Framework',
    ['qb-core'] = 'Framework',
    es_extended = 'Framework',
    ox_core = 'Framework',
    ox_inventory = 'Inventory',
    ['qb-inventory'] = 'Inventory',
    ox_target = 'Target',
    ['qb-target'] = 'Target',
    oxmysql = 'Database',
    ghmattimysql = 'Database',
    ['Renewed-Weathersync'] = 'Weather',
    ['qb-weathersync'] = 'Weather',
    cd_easytime = 'Weather',
    lation_ui = 'UI',
    ox_lib = 'UI',
    okokNotify = 'Notify'
}

local function timestamp()
    if not DTConfig.Console.timestamps then return '' end
    return ('[%s] '):format(os.date('%H:%M:%S'))
end

local function shouldWrite(level)
    if level == 'DEBUG' then return DTConfig.Debug and DTConfig.Console.enabled end
    if level == 'AUDIT' then return DTConfig.Console.enabled and DTConfig.Console.audit end
    return DTConfig.Console.enabled
end

local function encodeData(data)
    if data == nil then return '' end
    local ok, encoded = pcall(json.encode, data)
    return (' | %s'):format(ok and encoded or tostring(data))
end

local function write(level, scope, message, data)
    if not shouldWrite(level) then return end
    local colour = colours[level] or '^7'
    print(('%s%s[DTlib]^7 [%s] [%s] %s%s'):format(
        colour,
        timestamp(),
        level,
        scope or 'GENERAL',
        tostring(message),
        encodeData(data)
    ))
end

function DT.Logger.Info(scope, message, data) write('INFO', scope, message, data) end
function DT.Logger.Warn(scope, message, data) write('WARN', scope, message, data) end
function DT.Logger.Error(scope, message, data) write('ERROR', scope, message, data) end
function DT.Logger.Audit(scope, message, data) write('AUDIT', scope, message, data) end
function DT.Logger.Debug(scope, message, data) write('DEBUG', scope, message, data) end

function DT.Logger.Webhook(url, payload)
    if not url or url == '' then return false end
    PerformHttpRequest(url, function(status)
        if status < 200 or status >= 300 then
            DT.Logger.Warn('WEBHOOK', ('HTTP request returned %s'):format(status))
        end
    end, 'POST', json.encode(payload or {}), {['Content-Type'] = 'application/json'})
    return true
end

local function state(resource)
    return GetResourceState(resource) == 'started'
end

local function detect(preferred, aliases, candidates)
    if aliases[preferred] then preferred = aliases[preferred] end
    return DTUtils.detect(preferred, candidates)
end

function DT.Logger.GetRuntimeStatus()
    local framework = detect(DTConfig.Adapters.framework, {
        qbx = 'qbx_core', qbox = 'qbx_core', qb = 'qb-core', esx = 'es_extended', ox = 'ox_core', oxcore = 'ox_core'
    }, {'qbx_core', 'qb-core', 'es_extended', 'ox_core'})

    local inventory = detect(DTConfig.Adapters.inventory, {
        ox = 'ox_inventory', dtgrid = 'ox_inventory', qb = 'qb-inventory'
    }, {'ox_inventory', 'qb-inventory'})

    local target = detect(DTConfig.Adapters.target, {
        ox = 'ox_target', qb = 'qb-target'
    }, {'ox_target', 'qb-target'})

    local database = detect(DTConfig.Adapters.database, {
        ox = 'oxmysql'
    }, {'oxmysql', 'ghmattimysql'})

    local weather = detect(DTConfig.Adapters.weather, {
        renewed = 'Renewed-Weathersync', qb = 'qb-weathersync'
    }, {'Renewed-Weathersync', 'qb-weathersync', 'cd_easytime'})

    local uiConfigured = DTConfig.Adapters.ui or 'auto'
    if uiConfigured == 'lation' or uiConfigured == 'lationui' then uiConfigured = 'lation_ui' end
    if uiConfigured == 'ox' or uiConfigured == 'oxlib' then uiConfigured = 'ox_lib' end
    local ui
    if uiConfigured == 'native' or uiConfigured == 'dt' or uiConfigured == 'dtlib' then
        ui = 'native'
    else
        ui = detect(uiConfigured, {}, {'lation_ui', 'ox_lib'}) or 'native'
    end

    local tokenConfigured = GetConvar(DTConfig.Discord.tokenConvar, '') ~= ''
    local guildConfigured = GetConvar(DTConfig.Discord.guildIdConvar, '') ~= ''

    return {
        version = DT.Version,
        framework = framework or 'standalone',
        inventory = inventory or 'none',
        target = target or 'none',
        database = database or 'none',
        weather = weather or 'native',
        ui = ui,
        notify = DT.NotifyProvider and DT.NotifyProvider() or 'native',
        placement = (DT.GetAdapters and DT.GetAdapters().placement) or 'dtlib_gizmo',
        waypoint = (DTConfig.Waypoint and DTConfig.Waypoint.enabled) and 'dtlib_waypoint' or 'disabled',
        minigames = DT.Minigame.Provider(),
        discord = tokenConfigured and guildConfigured and 'configured' or 'not configured',
        debug = DTConfig.Debug,
        strict = DTConfig.Strict
    }
end

local function statusLabel(value, optional)
    if value == 'none' then return optional and '^3NONE^7' or '^1MISSING^7' end
    if value == 'not configured' then return '^3NOT CONFIGURED^7' end
    if value == 'disabled' then return '^3DISABLED^7' end
    if value == 'unavailable' then return '^1UNAVAILABLE^7' end
    if value == 'standalone' or value == 'native' then return ('^3%s^7'):format(value:upper()) end
    return ('^2%s^7'):format(tostring(value))
end

function DT.Logger.PrintStatus(reason)
    if not DTConfig.Console.enabled then return end
    local s = DT.Logger.GetRuntimeStatus()

    print('^5+----------------------------------------------------------+^7')
    print(('^5|^7 DTlib v%-48s^5|^7'):format(s.version))
    print('^5+----------------------------------------------------------+^7')
    print(('  Framework : %s'):format(statusLabel(s.framework, true)))
    print(('  Inventory : %s'):format(statusLabel(s.inventory, true)))
    print(('  Target    : %s'):format(statusLabel(s.target, true)))
    print(('  Database  : %s'):format(statusLabel(s.database, false)))
    print(('  Weather   : %s'):format(statusLabel(s.weather, true)))
    print(('  UI        : %s'):format(statusLabel(s.ui, true)))
    print(('  Notify    : %s'):format(statusLabel(s.notify, true)))
    print(('  Placement : %s'):format(statusLabel(s.placement, true)))
    print(('  Waypoint  : %s'):format(statusLabel(s.waypoint, true)))
    print(('  Minigames : %s'):format(statusLabel(s.minigames, true)))
    print(('  Discord   : %s'):format(statusLabel(s.discord, true)))
    print(('  Debug     : %s'):format(s.debug and '^3ON^7' or '^2OFF^7'))
    print(('  Strict    : %s'):format(s.strict and '^3ON^7' or '^2OFF^7'))
    if reason then print(('  Trigger   : %s'):format(reason)) end
    print('^5+----------------------------------------------------------+^7')

    if s.database == 'none' then
        DT.Logger.Error('BOOT', 'No supported database backend detected. Start oxmysql before DTlib.')
    end
    if s.inventory == 'none' then
        DT.Logger.Warn('BOOT', 'No supported inventory backend detected. Inventory API will be limited.')
    end
    if s.target == 'none' then
        DT.Logger.Warn('BOOT', 'No target backend detected. DT.Target calls will return no_target_backend.')
    end
    if s.discord == 'not configured' then
        DT.Logger.Warn('DISCORD', 'Discord integration is not configured. Token value is never printed.')
    end
end

RegisterCommand('dtlib:status', function(source)
    if source ~= 0 and not DT.Security.IsAdmin(source) then
        DT.Logger.Warn('SECURITY', ('Player %s attempted dtlib:status without permission'):format(source))
        return
    end
    DT.Logger.PrintStatus(source == 0 and 'server console command' or ('admin %s'):format(source))
end, false)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then return end
    local category = watchedResources[resource]
    if not category or not DTConfig.Console.resourceEvents then return end
    SetTimeout(250, function()
        if state(resource) then
            DT.Logger.Info('RESOURCE', ('%s backend started: %s'):format(category, resource))
        end
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then return end
    local category = watchedResources[resource]
    if not category or not DTConfig.Console.resourceEvents then return end
    DT.Logger.Warn('RESOURCE', ('%s backend stopped: %s'):format(category, resource))
end)
