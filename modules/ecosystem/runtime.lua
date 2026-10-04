-- DTlib provider registry. Factories are local Lua modules declared in fxmanifest.
DT.Providers = DT.Providers or {}
local P = DT.Providers
local definitions, instances = {}, {}
local server = IsDuplicityVersion()
P.Server = server
local sequence=0
function P.Id(prefix) sequence=sequence+1;return ('dtlib_%s_%s'):format(prefix or 'provider',sequence) end
local aliases = {textui='helptext',progress='progressbar',vehiclekeys='vehiclekey',boss='bossmenu',zone='zones'}
local resourceAliases = {lation='lation_ui',lationui='lation_ui',ox='ox_lib',oxlib='ox_lib',dt='native',dtlib='native',dtgrid='ox_inventory'}
local function categoryName(name) name=tostring(name or ''):lower();return aliases[name] or name end
function P.Register(category, resource, factory)
    category=categoryName(category)
    assert(DTEcosystemCatalog[category], 'unknown_provider_category')
    assert(type(factory)=='function', 'invalid_provider_factory')
    definitions[category]=definitions[category] or {}
    definitions[category][resource]=factory
end
function P.Export(resource, method, ...)
    if GetResourceState(resource)~='started' then return nil,'provider_not_started:'..resource end
    local handle=exports[resource]
    return handle[method](handle,...)
end
function P.Bind(resource, method)
    return function(...) return P.Export(resource,method,...) end
end
function P.WaitCallback(invoke)
    local pending=promise.new()
    local resolved=false
    invoke(function(...) if not resolved then resolved=true;pending:resolve(table.pack(...)) end end)
    local values=Citizen.Await(pending)
    return table.unpack(values,1,values.n)
end
function P.Event(event, ...)
    if server then TriggerEvent(event,...) else TriggerServerEvent(event,...) end
    return true
end
function P.Enabled() return not DTConfig.Ecosystem or DTConfig.Ecosystem.enabled~=false end
local function configured(category)
    local value=DTConfig.Ecosystem and DTConfig.Ecosystem.providers and DTConfig.Ecosystem.providers[category] or 'auto'
    if value~='auto' then return value end
    local key=({helptext='textui',progressbar='progress'})[category] or category
    value=DTConfig.Adapters[key] or 'auto'
    if value=='auto' and ({helptext=true,progressbar=true,menu=true,input=true})[category] then value=DTConfig.Adapters.ui or 'auto' end
    return value
end
local function eligible(category, definition)
    return definition[server and 'server' or 'client'] and definitions[category] and definitions[category][definition.resource]
        and (definition.default or GetResourceState(definition.resource)=='started')
end
local function selectProvider(category, wanted)
    local catalog=DTEcosystemCatalog[category]
    if not catalog then return nil,'unknown_category' end
    if not P.Enabled() then return nil,'disabled' end
    wanted=wanted or configured(category)
    if wanted=='none' or wanted=='disabled' or wanted=='off' then return nil,'disabled' end
    wanted=resourceAliases[wanted] or wanted
    if wanted=='qb' then wanted=category=='inventory' and 'qb-inventory' or category=='target' and 'qb-target' or 'qb-core' end
    for _,definition in ipairs(catalog.providers) do
        if (wanted=='auto' and not definition.default or wanted~='auto' and (definition.name:lower()==tostring(wanted):lower() or definition.resource:lower()==tostring(wanted):lower())) and eligible(category,definition) then return definition end
    end
    if wanted=='auto' then
        for _,definition in ipairs(catalog.providers) do
            if definition.default and eligible(category,definition) then return definition end
        end
    end
    return nil,wanted=='auto' and 'provider_unavailable' or 'provider_not_started_or_wrong_side'
end
DT.Ecosystem = {}
local E=DT.Ecosystem
function E.Provider(category)
    local provider,reason=selectProvider(categoryName(category))
    return provider and provider.resource or reason=='disabled' and 'disabled' or 'unavailable'
end
function E.Get(category, requested)
    category=categoryName(category)
    local provider,reason=selectProvider(category,requested)
    if not provider then return nil,reason end
    local key=category..':'..provider.resource
    if not instances[key] then
        local ok,api=pcall(definitions[category][provider.resource],provider.resource)
        if not ok then return nil,'provider_initialization_failed:'..tostring(api) end
        if type(api)~='table' then return nil,'invalid_provider_api' end
        api.GetResourceName=function() return provider.resource end
        -- Retain DT contracts, and expose every additional source-pack method.
        -- Providers are selected once per category in the source pack; restart after changing config.
        for _,method in ipairs(provider.methods) do
            if api[method]==nil then
                local categoryKey,resourceKey,methodKey=category,provider.resource,method
                api[method]=function(...)
                    local full,reason=DT.AdapterPack.Get(categoryKey,resourceKey)
                    if not full then return nil,reason end
                    if not DTUtils.isCallable(full[methodKey]) then return nil,'unsupported_method:'..methodKey end
                    return full[methodKey](...)
                end
            end
        end
        instances[key]=api
    end
    return instances[key]
end
function E.Call(category, method, ...)
    local api,reason=E.Get(category)
    if not api then return nil,reason end
    if not DTUtils.isCallable(api[method]) then return nil,'unsupported_method:'..tostring(method) end
    return api[method](...)
end
function E.List(category)
    category=categoryName(category)
    local result={}
    for _,p in ipairs(DTEcosystemCatalog[category] and DTEcosystemCatalog[category].providers or {}) do
        local methods={};local api=eligible(category,p) and E.Get(category,p.resource)
        for name,fn in pairs(api or {}) do if DTUtils.isCallable(fn) then methods[#methods+1]=name end end
        table.sort(methods)
        result[#result+1]={name=p.name,resource=p.resource,available=api~=nil and api~=false,client=p.client,server=p.server,methods=methods,declaredMethods=DTUtils.copy(p.methods)}
    end
    return result
end
function E.Status()
    local result={}
    for category in pairs(DTEcosystemCatalog) do
        local resource=E.Provider(category)
        result[category]={provider=resource,loaded=instances[category..':'..resource]~=nil}
    end
    return result
end
function E.Supports(category, method, resource)
    local api=E.Get(category,resource)
    return api~=nil and DTUtils.isCallable(api[method])
end
for category,definition in pairs(DTEcosystemCatalog) do
    local name=definition.namespace=='cZones' and 'Zones' or definition.namespace
    local api={}
    for _,p in ipairs(definition.providers) do
        for _,method in ipairs(p.methods) do
            local c,m=category,method
            api[m]=function(...) return E.Call(c,m,...) end
        end
    end
    local c=category
    api.Provider=function() return E.Provider(c) end
    api.Available=function() return E.Provider(c)~='unavailable' and E.Provider(c)~='disabled' end
    E[name]=api
    if not DT[name] then DT[name]=api end
end
local utilities={}
function P.RegisterUtility(name, api) utilities[name]=api end
function E.Utility(name)
    if utilities[name] then return utilities[name] end
    if DT.AdapterPack then return DT.AdapterPack.Utility(name) end
    return nil,'unknown_utility'
end
function E.Require(name)
    if type(name)~='string' or name:find('/',1,true) or name:find('..',1,true) then return nil,'invalid_module_name' end
    return E.Utility(name)
end
AddEventHandler(server and 'onResourceStop' or 'onClientResourceStop',function(name)
    for key in pairs(instances) do if key:sub(-#name-1)==':'..name then instances[key]=nil end end
end)
exports('GetEcosystem',function() return E end)
exports('GetEcosystemStatus',function() return E.Status() end)
exports('EcosystemCall',function(...) return E.Call(...) end)

-- Selected provider source loader: all source files are local DTlib modules.
do
-- Isolated, selected-provider runtime for the bundled GPL community adapter pack.
-- Does not require or impersonate the community_bridge resource.
DT.AdapterPack = {}
local E = DT.AdapterPack
local server = IsDuplicityVersion()
local side = server and 'server' or 'client'
local resource = GetCurrentResourceName()
local root = ''
local loaded, loading, selected, errors = {}, {}, {}, {}
local env = setmetatable({}, {__index = _G})
env._G = env
local function enabled() return not DTConfig.Ecosystem or DTConfig.Ecosystem.enabled ~= false end
local function callable(v) return DTUtils.isCallable(v) end
local function invoke(fn, ...) return DTUtils.safeCall(fn, ...) end
local function namespace(category) return DTAdapterCatalog[category] and DTAdapterCatalog[category].namespace end
local function canonical(category)
    category = tostring(category or ''):lower()
    local aliases = {vehiclekeys='vehiclekey',textui='helptext',progress='progressbar',boss='bossmenu',zone='zones'}
    return aliases[category] or category
end
local function config(category)
    local c = DTConfig.Ecosystem or {}
    local value=c.providers and c.providers[category] or 'auto'
    if value~='auto' then return value end
    local key=({helptext='textui',progressbar='progress'})[category] or category
    local adapter=DTConfig.Adapters[key]
    if adapter and adapter~='auto' then return adapter end
    if category=='helptext' or category=='input' or category=='menu' or category=='progressbar' then
        local ui=DTConfig.Adapters.ui
        if ui and ui~='auto' then return ui end
    end
    return value
end
-- Only selected resources are visible to upstream exclusion guards. A stopped
-- resource never blocks a live provider and explicit provider choices win.
local visible = {}
env.GetResourceState = function(name)
    local actual = GetResourceState(name)
    if actual ~= 'started' then return 'missing' end
    if visible[name] == false then return 'missing' end
    return actual
end
env.SendNUIMessage=function(message)
    if message.type then SendNUIMessage({action='ecosystem:dialogue',data=message}) else SendNUIMessage(message) end
end
env.exports = setmetatable({}, {__index = function(_, name) return exports[name] end, __call = function() end})
-- Preserve callback transport and source validation implemented by DTlib.
env.Callback = {}
function env.Callback.Register(name, handler) return DT.Callback.Register(name, handler) end
function env.Callback.Trigger(name, ...)
    local args = table.pack(...)
    local target
    if server then target = table.remove(args, 1); args.n = args.n - 1
    elseif args[1] == false then table.remove(args, 1); args.n = args.n - 1 end
    local cb
    if callable(args[1]) then cb = table.remove(args, 1); args.n = args.n - 1 end
    local function run()
        if server then return DT.Callback.AwaitClient(target, name, table.unpack(args, 1, args.n)) end
        return DT.Callback.Await(name, table.unpack(args, 1, args.n))
    end
    if cb then CreateThread(function() invoke(cb, run()) end); return end
    return run()
end
function env.Callback.RegisterRebound(name, fn) return DT.Callback.Register(name, fn) end
-- oxmysql-shaped facade keeps the bundled providers on DT's configured database.
if server then
    env.MySQL = {}
    for lower, upper in pairs({query='Query',single='Single',scalar='Scalar',insert='Insert',update='Update',prepare='Prepare',transaction='Transaction'}) do
        local name = upper
        env.MySQL[lower] = setmetatable({await=function(...) return DT.Database[name](...) end}, {__call=function(_, q, p, cb)
            CreateThread(function() local result=DT.Database[name](q,p); if callable(cb) then invoke(cb,result) end end)
        end})
    end
    env.MySQL.ready = function(fn) CreateThread(function() while not DT.Database.Available() do Wait(250) end; fn() end) end
end
local function execute(path, external)
    local key = (external or resource) .. ':' .. path
    if loaded[key] ~= nil then return loaded[key] end
    if loading[key] then return nil end
    local full = external and path or root .. path
    local body = LoadResourceFile(external or resource, full)
    if not body then error('missing_ecosystem_source:' .. full, 2) end
    local chunk, err = load(body, '@' .. resource .. '/' .. full, 't', env)
    if not chunk then error(err, 2) end
    loading[key] = true
    local ok, result = pcall(chunk)
    loading[key] = nil
    if not ok then error(result, 2) end
    loaded[key] = result == nil and true or result
    return result
end
function env.Require(path, owner)
    if owner == 'community_bridge' or owner == resource then owner = nil end
    if path == 'modules/target/_default/init.lua' then return E.Get('target') end
    if path == 'settings/sharedConfig.lua' then return env.BridgeSharedConfig end
    if path == 'settings/clientConfig.lua' then return env.BridgeClientConfig end
    if path == 'settings/serverConfig.lua' then return env.BridgeServerConfig end
    if path == 'lib/callback/shared/callback.lua' or path == 'lib/utility/shared/callbacks.lua' then return env.Callback end
    if path == 'lib/MySQL.lua' and owner == 'oxmysql' then return env.MySQL end
    return execute(path, owner)
end
env.BridgeSharedConfig = {Lang='en',DebugLevel=0,Notify='auto',HelpText='auto',Phone='auto',Skills='auto'}
env.BridgeClientConfig = {InputSystem='auto',MenuSystem='auto',ProgressBarSystem='auto',VehicleKey='auto',Fuel='auto',TargetSystem='auto',Debug=false}
env.BridgeServerConfig = {MaxInventorySlots=50,LogSystem='none',WebhookURL='',EmbedLogo=''}
env.Language = {Locale=function(key, ...)
    local lang = DTConfig.Ecosystem and DTConfig.Ecosystem.locale or 'en'
    local content = LoadResourceFile(resource, root .. 'locales/' .. lang .. '.json') or LoadResourceFile(resource, root .. 'locales/en.json')
    local data = content and json.decode(content) or {}
    for token in tostring(key):gmatch('[^.]+') do data = type(data)=='table' and data[token] or nil end
    if type(data)~='string' then return tostring(key) end
    if select('#',...)==0 then return data end
    local ok,result=pcall(string.format,data,...); return ok and result or data
end}
env.RequireLanguage = env.Language
env.locale=env.Language.Locale
local configKeys={notify={'shared','Notify'},helptext={'shared','HelpText'},phone={'shared','Phone'},skills={'shared','Skills'},input={'client','InputSystem'},menu={'client','MenuSystem'},progressbar={'client','ProgressBarSystem'},vehiclekey={'client','VehicleKey'},fuel={'client','Fuel'},target={'client','TargetSystem'}}
local function setConfig(category, value)
    local key=configKeys[category]
    if key then (key[1]=='shared' and env.BridgeSharedConfig or env.BridgeClientConfig)[key[2]]=value end
end
local function usable(p)
    return p.resource=='native' or DTUtils.isStarted(p.resource)
end
local function choose(category, forced)
    local catalog=DTAdapterCatalog[category]
    if not catalog then return nil,'unknown_category' end
    local wanted=tostring(forced or config(category))
    if wanted=='disabled' or wanted=='none' or wanted=='off' then return nil,'disabled' end
    local aliases={lation='lation_ui',lationui='lation_ui',ox='ox_lib',oxlib='ox_lib',dt='native',dtlib='native',dtgrid='ox_inventory',qb=category=='inventory' and 'qb-inventory' or category=='target' and 'qb-target' or 'qb-core'}
    wanted=aliases[wanted] or wanted
    if wanted~='auto' then
        for _,p in ipairs(catalog.providers) do
            if p.name:lower()==wanted:lower() or p.resource:lower()==wanted:lower() or (p.default and wanted=='native') then
                if usable(p) and (#p[side]>0 or #p.shared>0) then return p end
                return nil,'provider_not_started_or_wrong_side'
            end
        end
        return nil,'unknown_provider'
    end
    for _,p in ipairs(catalog.providers) do
        if not p.default and usable(p) and (#p[side]>0 or #p.shared>0) then return p end
    end
    -- State-backed defaults are available when deliberately configured native.
    return nil,'provider_unavailable'
end
function E.Provider(category)
    category=canonical(category)
    if not enabled() then return 'disabled' end
    local p=choose(category)
    return p and p.resource or 'unavailable'
end
function E.List(category)
    category=canonical(category)
    local out={}
    for _,p in ipairs(DTAdapterCatalog[category] and DTAdapterCatalog[category].providers or {}) do
        out[#out+1]={name=p.name,resource=p.resource,available=usable(p),client=#p.client>0,server=#p.server>0,methods=DTUtils.copy(p.methods)}
    end
    return out
end
-- Dependencies use lazy module proxies so their globals stay private.
local function proxy(category)
    return setmetatable({}, {__index=function(_, method)
        return function(...)
            local api,err=E.Get(category)
            local fn=api and api[method]
            if not callable(fn) then return nil,err or 'unsupported_backend' end
            return fn(...)
        end
    end})
end
env.Bridge={}
for category,c in pairs(DTAdapterCatalog) do
    local p=proxy(category)
    env[c.namespace]=p
    env.Bridge[c.namespace=='cZones' and 'Zones' or c.namespace]=p
end
-- Native defaults require a real table rather than a proxy while being loaded.
local busy={}
function E.Get(category, forced)
    category=canonical(category)
    if not enabled() then return nil,'disabled' end
    local p,reason=choose(category,forced)
    if not p then return nil,reason end
    local cached=selected[category]
    if cached then
        if cached.name==p.name then return env[namespace(category)] end
        return nil,'provider_changed_restart_dtlib'
    end
    if errors[category] then return nil,errors[category] end
    if busy[category] then return nil,'dependency_cycle:'..category end
    busy[category]=true
    local c=DTAdapterCatalog[category]
    local api={}
    env[c.namespace]=api
    -- Honor explicit selections even when competing inventory/clothing resources run.
    for _,other in ipairs(c.providers) do if other.resource~=p.resource and other.resource~='native' then visible[other.resource]=false end end
    visible[p.resource]=true
    setConfig(category,p.resource)
    local ok,err=pcall(function()
        env.Ids=env.Ids or execute('lib/utility/shared/ids.lua')
        env.Table=env.Table or execute('lib/utility/shared/tables.lua')
        env.Tables=env.Table
        env.Math=env.Math or execute('lib/utility/shared/math.lua')
        -- ox_lib is imported only for providers that use its lib.* helpers.
        if p.resource=='ox_lib' and not env.lib then execute('init.lua','ox_lib') end
        for _,d in ipairs(c.providers) do
            if d.default and not p.default then
                for _,path in ipairs(d.shared) do execute(path) end
                for _,path in ipairs(d[side]) do execute(path) end
            end
        end
        for _,path in ipairs(p.shared) do execute(path) end
        for _,path in ipairs(p[side]) do execute(path) end
        if type(env[c.namespace])~='table' then error('module_table_missing:'..category) end
    end)
    busy[category]=nil
    if not ok then errors[category]=tostring(err); return nil,tostring(err) end
    local initialized=env[c.namespace]
    initialized.GetResourceName=function() return p.resource end
    selected[category]=p
    errors[category]=nil
    return env[c.namespace]
end
function E.Call(category, method, ...)
    local api,err=E.Get(category)
    if not api then return nil,err end
    local fn=api[method]
    if not callable(fn) then return nil,'unsupported_backend' end
    return fn(...)
end
function E.Status()
    local out={}
    for category in pairs(DTAdapterCatalog) do
        out[category]={provider=E.Provider(category),loaded=selected[category]~=nil,error=errors[category]}
    end
    return out
end
-- New modules are direct DT APIs. Existing DT contracts keep their original names;
-- their full upstream-signature methods are available through DT.Ecosystem.*.
for category,c in pairs(DTAdapterCatalog) do
    local public=c.namespace=='cZones' and 'Zones' or c.namespace
    local api={}
    local methods={}
    for _,p in ipairs(c.providers) do for _,m in ipairs(p.methods) do methods[m]=true end end
    for m in pairs(methods) do local method=m; api[m]=function(...) return E.Call(category,method,...) end end
    api.Provider=function() return E.Provider(category) end
    api.Available=function() return E.Provider(category)~='unavailable' and E.Provider(category)~='disabled' end
    E[public]=api
    if not DT[public] then DT[public]=api end
end
local utilities={
    Ids='lib/utility/shared/ids.lua',Tables='lib/utility/shared/tables.lua',Prints='lib/utility/shared/prints.lua',Math='lib/utility/shared/math.lua',LA='lib/utility/shared/la.lua',
    Version='modules/version/server/VersionChecker.lua',
    Callback='lib/callback/shared/callback.lua',SQL='lib/sql/server/sqlHandler.lua',Logs='lib/logs/server/logs.lua',
    Scaleform='lib/scaleform/client/scaleform.lua',Placeable='lib/placers/client/object_Placer.lua',PlaceableObject='lib/placers/client/placeable_object.lua',
    Utility='lib/utility/client/utility.lua',Raycast='lib/raycast/client/raycast.lua',Point='lib/points/client/points.lua',Particle='lib/particles/client/particles.lua',
    Anim='lib/anim/client/client.lua',Cutscene='lib/cutscenes/client/cutscene.lua',Vehicles='lib/vehicles/client.lua'
}
utilities.Entity=server and 'lib/entities/server/server_entity.lua' or 'lib/entities/client/client_entity.lua'
utilities.Marker=server and 'lib/markers/server/server.lua' or 'lib/markers/client/markers.lua'
utilities.Shell=server and 'lib/shells/server/shells.lua' or 'lib/shells/client/shells.lua'
function E.Utility(name)
    local path=utilities[name]
    if not enabled() then return nil,'disabled' end
    if not path then return nil,'unknown_utility' end
    if (server and path:find('/client/')) or (not server and path:find('/server/')) then return nil,'wrong_runtime_side' end
    local ok,result=pcall(execute,path)
    if not ok then return nil,tostring(result) end
    env.Bridge[name]=result
    return result
end
for name in pairs(utilities) do
    local utilityName=name
    env.Bridge[name]=setmetatable({}, {__index=function(_,method)
        return function(...)
            local api,err=E.Utility(utilityName)
            local fn=type(api)=='table' and api[method]
            if not callable(fn) then return nil,err or 'unsupported_utility' end
            return fn(...)
        end
    end})
end
env.Bridge.ClientEntity=env.Bridge.Entity
E.Language=env.Language;DT.Language=DT.Language or E.Language
E.Version={}
for _,method in ipairs({'VersionChecker','AdvancedVersionChecker'}) do
    local name=method;E.Version[name]=function(...) local a,err=E.Utility('Version');if not a then return nil,err end;return a[name](...) end
end
E.Version.Check=E.Version.VersionChecker
DT.VersionChecker=DT.VersionChecker or E.Version
function E.Require(path,owner)
    if type(path)~='string' or path:find('..',1,true) or path:sub(1,1)=='/' or path:find('\\',1,true) then return nil,'invalid_path' end
    if owner and owner~=resource and owner~='community_bridge' and owner~='ox_lib' and owner~='PolyZone' and owner~='oxmysql' then return nil,'unsupported_source_resource' end
    local ok,result=pcall(env.Require,path,owner)
    if not ok then return nil,tostring(result) end
    return result
end
-- Preload configured live backends at boot so cross-side callback handlers exist
-- before any client opens an appearance form or sends a phone email.
CreateThread(function()
    Wait(0)
    if not enabled() then return end
    if DTUtils.isStarted('ox_lib') and not env.lib then
        local ok,err=pcall(execute,'init.lua','ox_lib');if not ok then DT.Debug('Ecosystem ox_lib import',err) end
    end
    local order={'framework','inventory','notify','helptext','input','menu','progressbar','target','weather','fuel','vehiclekey','banking','phone','doorlock','dispatch','clothing','housing','shops','skills','bossmenu','zones','dialogue'}
    for _,category in ipairs(order) do
        local p=choose(category)
        if p then local _,err=E.Get(category); if err then DT.Debug('Ecosystem',category,err) end end
    end
end)
exports('GetAdapterPack',function() return E end)
exports('GetAdapterPackStatus',function() return E.Status() end)
exports('AdapterPackCall',function(...) return E.Call(...) end)

end
