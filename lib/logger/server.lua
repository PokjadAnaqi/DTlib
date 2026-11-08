local colours = {
    INFO = '^2',
    WARN = '^3',
    ERROR = '^1',
    AUDIT = '^5',
    DEBUG = '^6',
}

local watchedResources = {
    qbx_core = 'Framework',
    ['qb-core'] = 'Framework',
    es_extended = 'Framework',
    ox_core = 'Framework',
    ox_inventory = 'Inventory',
    ['qb-inventory'] = 'Inventory',
    DT_interact = 'Target',
    ox_target = 'Target',
    ['qb-target'] = 'Target',
    sleepless_interact = 'Target',
    oxmysql = 'Database',
    ghmattimysql = 'Database',
    ['Renewed-Weathersync'] = 'Weather',
    ['qb-weathersync'] = 'Weather',
    cd_easytime = 'Weather',
    lation_ui = 'UI',
    ox_lib = 'UI',
    okokNotify = 'Notify',
}

local function timestamp()
    if not DTConfig.Console.timestamps then
        return ''
    end
    return ('[%s] '):format(os.date('%H:%M:%S'))
end

local function shouldWrite(level)
    if level == 'DEBUG' then
        return DTConfig.Debug and DTConfig.Console.enabled
    end
    if level == 'AUDIT' then
        return DTConfig.Console.enabled and DTConfig.Console.audit
    end
    return DTConfig.Console.enabled
end

local function encodeData(data)
    if data == nil or type(data) == 'table' and next(data) == nil then
        return ''
    end
    local ok, encoded = pcall(json.encode, data)
    return (' | %s'):format(ok and encoded or tostring(data))
end

local function write(level, scope, message, data)
    if not shouldWrite(level) then
        return
    end
    local colour = colours[level] or '^7'
    print(
        ('%s%s[DTlib]^7 [%s/%s] %s%s'):format(
            colour,
            timestamp(),
            level,
            scope or 'GENERAL',
            tostring(message),
            encodeData(data)
        )
    )
end

function DT.Logger.Info(scope, message, data)
    write('INFO', scope, message, data)
end
function DT.Logger.Warn(scope, message, data)
    write('WARN', scope, message, data)
end
function DT.Logger.Error(scope, message, data)
    write('ERROR', scope, message, data)
end
function DT.Logger.Audit(scope, message, data)
    write('AUDIT', scope, message, data)
end
function DT.Logger.Debug(scope, message, data)
    write('DEBUG', scope, message, data)
end

function DT.Logger.Webhook(url, payload)
    if not url or url == '' then
        return false
    end
    PerformHttpRequest(url, function(status)
        if status < 200 or status >= 300 then
            DT.Logger.Warn('WEBHOOK', ('HTTP request returned %s'):format(status))
        end
    end, 'POST', json.encode(payload or {}), { ['Content-Type'] = 'application/json' })
    return true
end

local function state(resource)
    return GetResourceState(resource) == 'started'
end

local function detect(preferred, aliases, candidates)
    if aliases[preferred] then
        preferred = aliases[preferred]
    end
    return DTUtils.detect(preferred, candidates)
end

function DT.Logger.GetRuntimeStatus()
    local framework = detect(DTConfig.Adapters.framework, {
        qbx = 'qbx_core',
        qbox = 'qbx_core',
        qb = 'qb-core',
        esx = 'es_extended',
        ox = 'ox_core',
        oxcore = 'ox_core',
    }, { 'qbx_core', 'qb-core', 'es_extended', 'ox_core' })

    local inventory = detect(DTConfig.Adapters.inventory, {
        ox = 'ox_inventory',
        dtgrid = 'ox_inventory',
        qb = 'qb-inventory',
    }, { 'ox_inventory', 'qb-inventory' })

    local targetPreferred = DTConfig.Adapters.target
    if DTConfig.Interaction and DTConfig.Interaction.mode == 'interact' then
        targetPreferred = 'DT_interact'
    end
    local targetAliases = { ox = 'ox_target', qb = 'qb-target', interact = 'DT_interact', dt_interact = 'DT_interact' }
    local targetCandidates = { 'DT_interact', 'ox_target', 'qb-target', 'sleepless_interact' }
    local target = detect(targetPreferred, targetAliases, targetCandidates)
    if not target and not (DTConfig.Interaction and DTConfig.Interaction.mode == 'interact') then
        target = detect('auto', targetAliases, targetCandidates)
    end

    local database = detect(DTConfig.Adapters.database, {
        ox = 'oxmysql',
    }, { 'oxmysql', 'ghmattimysql' })

    local weather = DT.Weather.Name and DT.Weather.Name() or 'native'

    local uiConfigured = DTConfig.Adapters.ui or 'auto'
    if uiConfigured == 'lation' or uiConfigured == 'lationui' then
        uiConfigured = 'lation_ui'
    end
    if uiConfigured == 'ox' or uiConfigured == 'oxlib' then
        uiConfigured = 'ox_lib'
    end
    local ui
    if uiConfigured == 'native' or uiConfigured == 'dt' or uiConfigured == 'dtlib' then
        ui = 'native'
    else
        ui = detect(uiConfigured, {}, { 'lation_ui', 'ox_lib' }) or 'native'
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
        strict = DTConfig.Strict,
    }
end

function DT.Logger.PrintStatus(reason)
    if not DTConfig.Console.enabled then
        return
    end

    local status = DT.Logger.GetRuntimeStatus()
    local summary = ('v%s | framework=%s | inventory=%s | target=%s | db=%s'):format(
        status.version,
        status.framework,
        status.inventory,
        status.target,
        status.database
    )
    if reason == 'resource start' then
        DT.Logger.Info('BOOT', summary)
        if status.database == 'none' then
            DT.Logger.Error('BOOT', 'No database backend. Start oxmysql before DTlib.')
        end
        return
    end

    DT.Logger.Info('STATUS', summary)
    DT.Logger.Info(
        'STATUS',
        ('weather=%s | ui=%s | notify=%s | waypoint=%s | placement=%s | minigames=%s | discord=%s | debug=%s | strict=%s'):format(
            status.weather,
            status.ui,
            status.notify,
            status.waypoint,
            status.placement,
            status.minigames,
            status.discord,
            tostring(status.debug),
            tostring(status.strict)
        )
    )
end

RegisterCommand('dtlib:status', function(source)
    if source ~= 0 and not DT.Security.IsAdmin(source) then
        DT.Logger.Warn('SECURITY', ('Player %s attempted dtlib:status without permission'):format(source))
        return
    end
    DT.Logger.PrintStatus(source == 0 and 'server console command' or ('admin %s'):format(source))
end, false)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        return
    end
    local category = watchedResources[resource]
    if not category or not DTConfig.Console.resourceEvents or not DTConfig.Debug then
        return
    end
    SetTimeout(250, function()
        if state(resource) then
            DT.Logger.Debug('RESOURCE', ('%s backend started: %s'):format(category, resource))
        end
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        return
    end
    local category = watchedResources[resource]
    if not category or not DTConfig.Console.resourceEvents or not DTConfig.Debug then
        return
    end
    DT.Logger.Debug('RESOURCE', ('%s backend stopped: %s'):format(category, resource))
end)
