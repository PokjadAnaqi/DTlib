-- DTlib provider registry. Factories are local Lua modules declared in fxmanifest.
DT.Providers = DT.Providers or {}
local providerRegistry = DT.Providers
local definitions, instances = {}, {}
local server = IsDuplicityVersion()
providerRegistry.Server = server
local sequence = 0
function providerRegistry.Id(prefix)
    sequence = sequence + 1
    return ('dtlib_%s_%s'):format(prefix or 'provider', sequence)
end
local aliases =
    { textui = 'helptext', progress = 'progressbar', vehiclekeys = 'vehiclekey', boss = 'bossmenu', zone = 'zones' }
local resourceAliases = {
    lation = 'lation_ui',
    lationui = 'lation_ui',
    ox = 'ox_lib',
    oxlib = 'ox_lib',
    dt = 'native',
    dtlib = 'native',
    dtgrid = 'ox_inventory',
}
local function categoryName(name)
    name = tostring(name or ''):lower()
    return aliases[name] or name
end
function providerRegistry.Register(category, resource, factory)
    category = categoryName(category)
    assert(DTEcosystemCatalog[category], 'unknown_provider_category')
    assert(type(factory) == 'function', 'invalid_provider_factory')
    definitions[category] = definitions[category] or {}
    definitions[category][resource] = factory
end
function providerRegistry.Export(resource, method, ...)
    if GetResourceState(resource) ~= 'started' then
        return nil, 'provider_not_started:' .. resource
    end
    local handle = exports[resource]
    return handle[method](handle, ...)
end
function providerRegistry.Bind(resource, method)
    return function(...)
        return providerRegistry.Export(resource, method, ...)
    end
end
function providerRegistry.WaitCallback(invoke)
    local pending = promise.new()
    local resolved = false
    invoke(function(...)
        if not resolved then
            resolved = true
            pending:resolve(table.pack(...))
        end
    end)
    local values = Citizen.Await(pending)
    return table.unpack(values, 1, values.n)
end
function providerRegistry.Event(event, ...)
    if server then
        TriggerEvent(event, ...)
    else
        TriggerServerEvent(event, ...)
    end
    return true
end
function providerRegistry.Enabled()
    return not DTConfig.Ecosystem or DTConfig.Ecosystem.enabled ~= false
end
local function configured(category)
    local value = DTConfig.Ecosystem and DTConfig.Ecosystem.providers and DTConfig.Ecosystem.providers[category]
        or 'auto'
    if value ~= 'auto' then
        return value
    end
    local key = ({ helptext = 'textui', progressbar = 'progress' })[category] or category
    value = DTConfig.Adapters[key] or 'auto'
    if value == 'auto' and ({ helptext = true, progressbar = true, menu = true, input = true })[category] then
        value = DTConfig.Adapters.ui or 'auto'
    end
    return value
end
local function eligible(category, definition)
    return definition[server and 'server' or 'client']
        and definitions[category]
        and definitions[category][definition.resource]
        and (definition.default or GetResourceState(definition.resource) == 'started')
end
local function selectProvider(category, wanted)
    local catalog = DTEcosystemCatalog[category]
    if not catalog then
        return nil, 'unknown_category'
    end
    if not providerRegistry.Enabled() then
        return nil, 'disabled'
    end
    wanted = wanted or configured(category)
    if wanted == 'none' or wanted == 'disabled' or wanted == 'off' then
        return nil, 'disabled'
    end
    if category == 'weather' then
        wanted = tostring(wanted):lower()
        wanted = ({
            qb = 'qb-weathersync',
            renewed = 'Renewed-Weathersync',
            easytime = 'cd_easytime',
            ['cd-easytime'] = 'cd_easytime',
        })[wanted] or wanted
        if wanted == 'auto' and DT.Weather.Name then
            wanted = DT.Weather.Name()
        end
    end
    wanted = resourceAliases[wanted] or wanted
    if wanted == 'qb' then
        wanted = category == 'inventory' and 'qb-inventory' or category == 'target' and 'qb-target' or 'qb-core'
    end
    for _, definition in ipairs(catalog.providers) do
        if
            (
                wanted == 'auto' and not definition.default
                or wanted ~= 'auto'
                    and (definition.name:lower() == tostring(wanted):lower() or definition.resource:lower() == tostring(
                        wanted
                    ):lower())
            ) and eligible(category, definition)
        then
            return definition
        end
    end
    if wanted == 'auto' then
        for _, definition in ipairs(catalog.providers) do
            if definition.default and eligible(category, definition) then
                return definition
            end
        end
    end
    return nil, wanted == 'auto' and 'provider_unavailable' or 'provider_not_started_or_wrong_side'
end
DT.Ecosystem = {}
local ecosystem = DT.Ecosystem
function ecosystem.Provider(category)
    local provider, reason = selectProvider(categoryName(category))
    return provider and provider.resource or reason == 'disabled' and 'disabled' or 'unavailable'
end
function ecosystem.Get(category, requested)
    category = categoryName(category)
    local provider, reason = selectProvider(category, requested)
    if not provider then
        return nil, reason
    end
    local key = category .. ':' .. provider.resource
    if not instances[key] then
        local ok, api = pcall(definitions[category][provider.resource], provider.resource)
        if not ok then
            return nil, 'provider_initialization_failed:' .. tostring(api)
        end
        if type(api) ~= 'table' then
            return nil, 'invalid_provider_api'
        end
        api.GetResourceName = function()
            return provider.resource
        end
        -- Retain DT contracts, and expose every additional source-pack method.
        -- Providers are selected once per category in the source pack; restart after changing config.
        for _, method in ipairs(provider.methods) do
            if api[method] == nil then
                local categoryKey, resourceKey, methodKey = category, provider.resource, method
                api[method] = function(...)
                    local full, reason = DT.AdapterPack.Get(categoryKey, resourceKey)
                    if not full then
                        return nil, reason
                    end
                    if not DTUtils.isCallable(full[methodKey]) then
                        return nil, 'unsupported_method:' .. methodKey
                    end
                    return full[methodKey](...)
                end
            end
        end
        instances[key] = api
    end
    return instances[key]
end
function ecosystem.Call(category, method, ...)
    local api, reason = ecosystem.Get(category)
    if not api then
        return nil, reason
    end
    if not DTUtils.isCallable(api[method]) then
        return nil, 'unsupported_method:' .. tostring(method)
    end
    return api[method](...)
end
function ecosystem.List(category)
    category = categoryName(category)
    local result = {}
    for _, selectedAdapter in ipairs(DTEcosystemCatalog[category] and DTEcosystemCatalog[category].providers or {}) do
        local methods = {}
        local api = eligible(category, selectedAdapter) and ecosystem.Get(category, selectedAdapter.resource)
        for name, callback in pairs(api or {}) do
            if DTUtils.isCallable(callback) then
                methods[#methods + 1] = name
            end
        end
        table.sort(methods)
        result[#result + 1] = {
            name = selectedAdapter.name,
            resource = selectedAdapter.resource,
            available = api ~= nil and api ~= false,
            client = selectedAdapter.client,
            server = selectedAdapter.server,
            methods = methods,
            declaredMethods = DTUtils.copy(selectedAdapter.methods),
        }
    end
    return result
end
function ecosystem.Status()
    local result = {}
    for category in pairs(DTEcosystemCatalog) do
        local resource = ecosystem.Provider(category)
        result[category] = { provider = resource, loaded = instances[category .. ':' .. resource] ~= nil }
    end
    return result
end
function ecosystem.Supports(category, method, resource)
    local api = ecosystem.Get(category, resource)
    return api ~= nil and DTUtils.isCallable(api[method])
end
for category, definition in pairs(DTEcosystemCatalog) do
    local name = definition.namespace == 'cZones' and 'Zones' or definition.namespace
    local api = {}
    for _, candidate in ipairs(definition.providers) do
        for _, method in ipairs(candidate.methods) do
            local coreObject, methodName = category, method
            api[methodName] = function(...)
                return ecosystem.Call(coreObject, methodName, ...)
            end
        end
    end
    local entry = category
    api.Provider = function()
        return ecosystem.Provider(entry)
    end
    api.Available = function()
        return ecosystem.Provider(entry) ~= 'unavailable' and ecosystem.Provider(entry) ~= 'disabled'
    end
    ecosystem[name] = api
    if not DT[name] then
        DT[name] = api
    end
end
local utilities = {}
function providerRegistry.RegisterUtility(name, api)
    utilities[name] = api
end
function ecosystem.Utility(name)
    if utilities[name] then
        return utilities[name]
    end
    if DT.AdapterPack then
        return DT.AdapterPack.Utility(name)
    end
    return nil, 'unknown_utility'
end
function ecosystem.Require(name)
    if type(name) ~= 'string' or name:find('/', 1, true) or name:find('..', 1, true) then
        return nil, 'invalid_module_name'
    end
    return ecosystem.Utility(name)
end
AddEventHandler(server and 'onResourceStop' or 'onClientResourceStop', function(name)
    for key in pairs(instances) do
        if key:sub(-#name - 1) == ':' .. name then
            instances[key] = nil
        end
    end
end)
exports('GetEcosystem', function()
    return ecosystem
end)
exports('GetEcosystemStatus', function()
    return ecosystem.Status()
end)
exports('EcosystemCall', function(...)
    return ecosystem.Call(...)
end)

-- Selected provider source loader: all source files are local DTlib modules.
do
    -- Isolated, selected-provider runtime for the bundled GPL community adapter pack.
    -- Does not require or impersonate the community_bridge resource.
    DT.AdapterPack = {}
    local adapterPack = DT.AdapterPack
    local server = IsDuplicityVersion()
    local side = server and 'server' or 'client'
    local resource = GetCurrentResourceName()
    local root = ''
    local loaded, loading, selected, errors = {}, {}, {}, {}
    local env = setmetatable({}, { __index = _G })
    env._G = env
    local function enabled()
        return not DTConfig.Ecosystem or DTConfig.Ecosystem.enabled ~= false
    end
    local function callable(entryValue)
        return DTUtils.isCallable(entryValue)
    end
    local function invoke(callback, ...)
        return DTUtils.safeCall(callback, ...)
    end
    local function namespace(category)
        return DTAdapterCatalog[category] and DTAdapterCatalog[category].namespace
    end
    local function canonical(category)
        category = tostring(category or ''):lower()
        local aliases = {
            vehiclekeys = 'vehiclekey',
            textui = 'helptext',
            progress = 'progressbar',
            boss = 'bossmenu',
            zone = 'zones',
        }
        return aliases[category] or category
    end
    local function config(category)
        local ecosystemConfig = DTConfig.Ecosystem or {}
        local value = ecosystemConfig.providers and ecosystemConfig.providers[category] or 'auto'
        if value ~= 'auto' then
            return value
        end
        local key = ({ helptext = 'textui', progressbar = 'progress' })[category] or category
        local adapter = DTConfig.Adapters[key]
        if adapter and adapter ~= 'auto' then
            return adapter
        end
        if category == 'helptext' or category == 'input' or category == 'menu' or category == 'progressbar' then
            local ui = DTConfig.Adapters.ui
            if ui and ui ~= 'auto' then
                return ui
            end
        end
        return value
    end
    -- Only selected resources are visible to upstream exclusion guards. A stopped
    -- resource never blocks a live provider and explicit provider choices win.
    local visible = {}
    env.GetResourceState = function(name)
        local actual = GetResourceState(name)
        if actual ~= 'started' then
            return 'missing'
        end
        if visible[name] == false then
            return 'missing'
        end
        return actual
    end
    env.SendNUIMessage = function(message)
        if message.type then
            SendNUIMessage({ action = 'ecosystem:dialogue', data = message })
        else
            SendNUIMessage(message)
        end
    end
    env.exports = setmetatable({}, {
        __index = function(_, name)
            return exports[name]
        end,
        __call = function() end,
    })
    -- Preserve callback transport and source validation implemented by DTlib.
    env.Callback = {}
    function env.Callback.Register(name, handler)
        return DT.Callback.Register(name, handler)
    end
    function env.Callback.Trigger(name, ...)
        local arguments = table.pack(...)
        local target
        if server then
            target = table.remove(arguments, 1)
            arguments.n = arguments.n - 1
        elseif arguments[1] == false then
            table.remove(arguments, 1)
            arguments.n = arguments.n - 1
        end
        local callback
        if callable(arguments[1]) then
            callback = table.remove(arguments, 1)
            arguments.n = arguments.n - 1
        end
        local function run()
            if server then
                return DT.Callback.AwaitClient(target, name, table.unpack(arguments, 1, arguments.n))
            end
            return DT.Callback.Await(name, table.unpack(arguments, 1, arguments.n))
        end
        if callback then
            CreateThread(function()
                invoke(callback, run())
            end)
            return
        end
        return run()
    end
    function env.Callback.RegisterRebound(name, callback)
        return DT.Callback.Register(name, callback)
    end
    -- oxmysql-shaped facade keeps the bundled providers on DT's configured database.
    if server then
        env.MySQL = {}
        for lower, upper in pairs({
            query = 'Query',
            single = 'Single',
            scalar = 'Scalar',
            insert = 'Insert',
            update = 'Update',
            prepare = 'Prepare',
            transaction = 'Transaction',
        }) do
            local name = upper
            env.MySQL[lower] = setmetatable({
                await = function(...)
                    return DT.Database[name](...)
                end,
            }, {
                __call = function(_, query, payload, callback)
                    CreateThread(function()
                        local result = DT.Database[name](query, payload)
                        if callable(callback) then
                            invoke(callback, result)
                        end
                    end)
                end,
            })
        end
        env.MySQL.ready = function(callback)
            CreateThread(function()
                while not DT.Database.Available() do
                    Wait(250)
                end
                callback()
            end)
        end
    end
    local function execute(path, external)
        local key = (external or resource) .. ':' .. path
        if loaded[key] ~= nil then
            return loaded[key]
        end
        if loading[key] then
            return nil
        end
        local full = external and path or root .. path
        local body = LoadResourceFile(external or resource, full)
        if not body then
            error('missing_ecosystem_source:' .. full, 2)
        end
        local chunk, errorMessage = load(body, '@' .. resource .. '/' .. full, 't', env)
        if not chunk then
            error(errorMessage, 2)
        end
        loading[key] = true
        local ok, result = pcall(chunk)
        loading[key] = nil
        if not ok then
            error(result, 2)
        end
        loaded[key] = result == nil and true or result
        return result
    end
    function env.Require(path, owner)
        if owner == 'community_bridge' or owner == resource then
            owner = nil
        end
        if path == 'modules/target/_default/init.lua' then
            return adapterPack.Get('target')
        end
        if path == 'config/shared.lua' or path == 'settings/sharedConfig.lua' then
            return env.BridgeSharedConfig
        end
        if path == 'config/client.lua' or path == 'settings/clientConfig.lua' then
            return env.BridgeClientConfig
        end
        if path == 'config/server.lua' or path == 'settings/serverConfig.lua' then
            return env.BridgeServerConfig
        end
        if path == 'lib/callback/shared/callback.lua' or path == 'lib/utility/shared/callbacks.lua' then
            return env.Callback
        end
        if path == 'lib/MySQL.lua' and owner == 'oxmysql' then
            return env.MySQL
        end
        return execute(path, owner)
    end
    env.BridgeSharedConfig =
        { Lang = 'en', DebugLevel = 0, Notify = 'auto', HelpText = 'auto', Phone = 'auto', Skills = 'auto' }
    env.BridgeClientConfig = {
        InputSystem = 'auto',
        MenuSystem = 'auto',
        ProgressBarSystem = 'auto',
        VehicleKey = 'auto',
        Fuel = 'auto',
        TargetSystem = 'auto',
        Debug = false,
    }
    env.BridgeServerConfig = { MaxInventorySlots = 50, LogSystem = 'none', WebhookURL = '', EmbedLogo = '' }
    env.Language = {
        Locale = function(key, ...)
            local lang = DTConfig.Ecosystem and DTConfig.Ecosystem.locale or 'en'
            local content = LoadResourceFile(resource, root .. 'locales/' .. lang .. '.json')
                or LoadResourceFile(resource, root .. 'locales/en.json')
            local data = content and json.decode(content) or {}
            for token in tostring(key):gmatch('[^.]+') do
                data = type(data) == 'table' and data[token] or nil
            end
            if type(data) ~= 'string' then
                return tostring(key)
            end
            if select('#', ...) == 0 then
                return data
            end
            local ok, result = pcall(string.format, data, ...)
            return ok and result or data
        end,
    }
    env.RequireLanguage = env.Language
    env.locale = env.Language.Locale
    local configKeys = {
        notify = { 'shared', 'Notify' },
        helptext = { 'shared', 'HelpText' },
        phone = { 'shared', 'Phone' },
        skills = { 'shared', 'Skills' },
        input = { 'client', 'InputSystem' },
        menu = { 'client', 'MenuSystem' },
        progressbar = { 'client', 'ProgressBarSystem' },
        vehiclekey = { 'client', 'VehicleKey' },
        fuel = { 'client', 'Fuel' },
        target = { 'client', 'TargetSystem' },
    }
    local function setConfig(category, value)
        local key = configKeys[category]
        if key then
            (key[1] == 'shared' and env.BridgeSharedConfig or env.BridgeClientConfig)[key[2]] = value
        end
    end
    local function usable(selectedAdapter)
        return selectedAdapter.resource == 'native' or DTUtils.isStarted(selectedAdapter.resource)
    end
    local function choose(category, forced)
        local catalog = DTAdapterCatalog[category]
        if not catalog then
            return nil, 'unknown_category'
        end
        local wanted = tostring(forced or config(category))
        if category == 'weather' then
            wanted = wanted:lower()
            wanted = ({
                qb = 'qb-weathersync',
                renewed = 'Renewed-Weathersync',
                easytime = 'cd_easytime',
                ['cd-easytime'] = 'cd_easytime',
            })[wanted] or wanted
            if wanted == 'auto' and DT.Weather.Name then
                wanted = DT.Weather.Name()
            end
        end
        if wanted == 'disabled' or wanted == 'none' or wanted == 'off' then
            return nil, 'disabled'
        end
        local aliases = {
            lation = 'lation_ui',
            lationui = 'lation_ui',
            ox = 'ox_lib',
            oxlib = 'ox_lib',
            dt = 'native',
            dtlib = 'native',
            dtgrid = 'ox_inventory',
            qb = category == 'inventory' and 'qb-inventory' or category == 'target' and 'qb-target' or 'qb-core',
        }
        wanted = aliases[wanted] or wanted
        if wanted ~= 'auto' then
            for _, selectedAdapter in ipairs(catalog.providers) do
                if
                    selectedAdapter.name:lower() == wanted:lower()
                    or selectedAdapter.resource:lower() == wanted:lower()
                    or (selectedAdapter.default and wanted == 'native')
                then
                    if usable(selectedAdapter) and (#selectedAdapter[side] > 0 or #selectedAdapter.shared > 0) then
                        return selectedAdapter
                    end
                    return nil, 'provider_not_started_or_wrong_side'
                end
            end
            return nil, 'unknown_provider'
        end
        for _, candidate in ipairs(catalog.providers) do
            if not candidate.default and usable(candidate) and (#candidate[side] > 0 or #candidate.shared > 0) then
                return candidate
            end
        end
        -- State-backed defaults are available when deliberately configured native.
        return nil, 'provider_unavailable'
    end
    function adapterPack.Provider(category)
        category = canonical(category)
        if not enabled() then
            return 'disabled'
        end
        local selectedAdapter = choose(category)
        return selectedAdapter and selectedAdapter.resource or 'unavailable'
    end
    function adapterPack.List(category)
        category = canonical(category)
        local out = {}
        for _, selectedAdapter in ipairs(DTAdapterCatalog[category] and DTAdapterCatalog[category].providers or {}) do
            out[#out + 1] = {
                name = selectedAdapter.name,
                resource = selectedAdapter.resource,
                available = usable(selectedAdapter),
                client = #selectedAdapter.client > 0,
                server = #selectedAdapter.server > 0,
                methods = DTUtils.copy(selectedAdapter.methods),
            }
        end
        return out
    end
    -- Dependencies use lazy module proxies so their globals stay private.
    local function proxy(category)
        return setmetatable({}, {
            __index = function(_, method)
                return function(...)
                    local api, errorMessage = adapterPack.Get(category)
                    local callback = api and api[method]
                    if not callable(callback) then
                        return nil, errorMessage or 'unsupported_backend'
                    end
                    return callback(...)
                end
            end,
        })
    end
    env.Bridge = {}
    for category, coreObject in pairs(DTAdapterCatalog) do
        local payload = proxy(category)
        env[coreObject.namespace] = payload
        env.Bridge[coreObject.namespace == 'cZones' and 'Zones' or coreObject.namespace] = payload
    end
    -- Native defaults require a real table rather than a proxy while being loaded.
    local busy = {}
    function adapterPack.Get(category, forced)
        category = canonical(category)
        if not enabled() then
            return nil, 'disabled'
        end
        local selectedAdapter, reason = choose(category, forced)
        if not selectedAdapter then
            return nil, reason
        end
        -- Weather has a live DTlib provider factory; keep legacy calls on that same
        -- selection instead of pinning the first source-pack weather module.
        if category == 'weather' and DT.Weather.Name then
            return DT.Ecosystem.Get(category, selectedAdapter.resource)
        end
        local cached = selected[category]
        if cached then
            if cached.name == selectedAdapter.name then
                return env[namespace(category)]
            end
            return nil, 'provider_changed_restart_dtlib'
        end
        if errors[category] then
            return nil, errors[category]
        end
        if busy[category] then
            return nil, 'dependency_cycle:' .. category
        end
        busy[category] = true
        local categoryCatalog = DTAdapterCatalog[category]
        local api = {}
        env[categoryCatalog.namespace] = api
        -- Honor explicit selections even when competing inventory/clothing resources run.
        for _, other in ipairs(categoryCatalog.providers) do
            if other.resource ~= selectedAdapter.resource and other.resource ~= 'native' then
                visible[other.resource] = false
            end
        end
        visible[selectedAdapter.resource] = true
        setConfig(category, selectedAdapter.resource)
        local ok, errorMessage = pcall(function()
            env.Ids = env.Ids or execute('lib/utility/shared/ids.lua')
            env.Table = env.Table or execute('lib/utility/shared/tables.lua')
            env.Tables = env.Table
            env.Math = env.Math or execute('lib/utility/shared/math.lua')
            -- ox_lib is imported only for providers that use its lib.* helpers.
            if selectedAdapter.resource == 'ox_lib' and not env.lib then
                execute('init.lua', 'ox_lib')
            end
            for _, candidate in ipairs(categoryCatalog.providers) do
                if candidate.default and not selectedAdapter.default then
                    for _, path in ipairs(candidate.shared) do
                        execute(path)
                    end
                    for _, path in ipairs(candidate[side]) do
                        execute(path)
                    end
                end
            end
            for _, path in ipairs(selectedAdapter.shared) do
                execute(path)
            end
            for _, path in ipairs(selectedAdapter[side]) do
                execute(path)
            end
            if type(env[categoryCatalog.namespace]) ~= 'table' then
                error('module_table_missing:' .. category)
            end
        end)
        busy[category] = nil
        if not ok then
            errors[category] = tostring(errorMessage)
            return nil, tostring(errorMessage)
        end
        local initialized = env[categoryCatalog.namespace]
        initialized.GetResourceName = function()
            return selectedAdapter.resource
        end
        selected[category] = selectedAdapter
        errors[category] = nil
        return env[categoryCatalog.namespace]
    end
    function adapterPack.Call(category, method, ...)
        local api, errorMessage = adapterPack.Get(category)
        if not api then
            return nil, errorMessage
        end
        local callback = api[method]
        if not callable(callback) then
            return nil, 'unsupported_backend'
        end
        return callback(...)
    end
    function adapterPack.Status()
        local out = {}
        for category in pairs(DTAdapterCatalog) do
            out[category] = {
                provider = adapterPack.Provider(category),
                loaded = selected[category] ~= nil,
                error = errors[category],
            }
        end
        return out
    end
    -- New modules are direct DT APIs. Existing DT contracts keep their original names;
    -- their full upstream-signature methods are available through DT.Ecosystem.*.
    for category, coreObject in pairs(DTAdapterCatalog) do
        local public = coreObject.namespace == 'cZones' and 'Zones' or coreObject.namespace
        local api = {}
        local methods = {}
        for _, candidate in ipairs(coreObject.providers) do
            for _, methodName in ipairs(candidate.methods) do
                methods[methodName] = true
            end
        end
        for methodName in pairs(methods) do
            local method = methodName
            api[methodName] = function(...)
                return adapterPack.Call(category, method, ...)
            end
        end
        api.Provider = function()
            return adapterPack.Provider(category)
        end
        api.Available = function()
            return adapterPack.Provider(category) ~= 'unavailable' and adapterPack.Provider(category) ~= 'disabled'
        end
        adapterPack[public] = api
        if not DT[public] then
            DT[public] = api
        end
    end
    local utilities = {
        Ids = 'lib/utility/shared/ids.lua',
        Tables = 'lib/utility/shared/tables.lua',
        Prints = 'lib/utility/shared/prints.lua',
        Math = 'lib/utility/shared/math.lua',
        LA = 'lib/utility/shared/la.lua',
        Version = 'modules/version/server/VersionChecker.lua',
        Callback = 'lib/callback/shared/callback.lua',
        SQL = 'lib/sql/server/sqlHandler.lua',
        Logs = 'lib/logs/server/logs.lua',
        Scaleform = 'lib/scaleform/client/scaleform.lua',
        Placeable = 'lib/placers/client/object_Placer.lua',
        PlaceableObject = 'lib/placers/client/placeable_object.lua',
        Utility = 'lib/utility/client/utility.lua',
        Raycast = 'lib/raycast/client/raycast.lua',
        Point = 'lib/points/client/points.lua',
        Particle = 'lib/particles/client/particles.lua',
        Anim = 'lib/anim/client/client.lua',
        Cutscene = 'lib/cutscenes/client/cutscene.lua',
        Vehicles = 'lib/vehicles/client.lua',
    }
    utilities.Entity = server and 'lib/entities/server/server_entity.lua' or 'lib/entities/client/client_entity.lua'
    utilities.Marker = server and 'lib/markers/server/server.lua' or 'lib/markers/client/markers.lua'
    utilities.Shell = server and 'lib/shells/server/shells.lua' or 'lib/shells/client/shells.lua'
    function adapterPack.Utility(name)
        local path = utilities[name]
        if not enabled() then
            return nil, 'disabled'
        end
        if not path then
            return nil, 'unknown_utility'
        end
        if (server and path:find('/client/')) or (not server and path:find('/server/')) then
            return nil, 'wrong_runtime_side'
        end
        local ok, result = pcall(execute, path)
        if not ok then
            return nil, tostring(result)
        end
        env.Bridge[name] = result
        return result
    end
    for name in pairs(utilities) do
        local utilityName = name
        env.Bridge[name] = setmetatable({}, {
            __index = function(_, method)
                return function(...)
                    local api, errorMessage = adapterPack.Utility(utilityName)
                    local callback = type(api) == 'table' and api[method]
                    if not callable(callback) then
                        return nil, errorMessage or 'unsupported_utility'
                    end
                    return callback(...)
                end
            end,
        })
    end
    env.Bridge.ClientEntity = env.Bridge.Entity
    adapterPack.Language = env.Language
    DT.Language = DT.Language or adapterPack.Language
    adapterPack.Version = {}
    for _, method in ipairs({ 'VersionChecker', 'AdvancedVersionChecker' }) do
        local name = method
        adapterPack.Version[name] = function(...)
            local left, errorMessage = adapterPack.Utility('Version')
            if not left then
                return nil, errorMessage
            end
            return left[name](...)
        end
    end
    adapterPack.Version.Check = adapterPack.Version.VersionChecker
    DT.VersionChecker = DT.VersionChecker or adapterPack.Version
    function adapterPack.Require(path, owner)
        if type(path) ~= 'string' or path:find('..', 1, true) or path:sub(1, 1) == '/' or path:find('\\', 1, true) then
            return nil, 'invalid_path'
        end
        if
            owner
            and owner ~= resource
            and owner ~= 'community_bridge'
            and owner ~= 'ox_lib'
            and owner ~= 'PolyZone'
            and owner ~= 'oxmysql'
        then
            return nil, 'unsupported_source_resource'
        end
        local ok, result = pcall(env.Require, path, owner)
        if not ok then
            return nil, tostring(result)
        end
        return result
    end
    -- Preload configured live backends at boot so cross-side callback handlers exist
    -- before any client opens an appearance form or sends a phone email.
    CreateThread(function()
        Wait(0)
        if not enabled() then
            return
        end
        if DTUtils.isStarted('ox_lib') and not env.lib then
            local ok, errorMessage = pcall(execute, 'init.lua', 'ox_lib')
            if not ok then
                DT.Debug('Ecosystem ox_lib import', errorMessage)
            end
        end
        local order = {
            'framework',
            'inventory',
            'notify',
            'helptext',
            'input',
            'menu',
            'progressbar',
            'target',
            'weather',
            'fuel',
            'vehiclekey',
            'banking',
            'phone',
            'doorlock',
            'dispatch',
            'clothing',
            'housing',
            'shops',
            'skills',
            'bossmenu',
            'zones',
            'dialogue',
        }
        for _, category in ipairs(order) do
            local payload = choose(category)
            if payload then
                local _, errorMessage = adapterPack.Get(category)
                if errorMessage then
                    DT.Debug('Ecosystem', category, errorMessage)
                end
            end
        end
    end)
    exports('GetAdapterPack', function()
        return adapterPack
    end)
    exports('GetAdapterPackStatus', function()
        return adapterPack.Status()
    end)
    exports('AdapterPackCall', function(...)
        return adapterPack.Call(...)
    end)
end
