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
