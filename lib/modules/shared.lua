DT.Modules = DT.Modules or {}
DT.Modules._providers = DT.Modules._providers or {}
DT.Modules._selected = DT.Modules._selected or {}

local function normalizeCategory(category)
    return tostring(category or ''):lower()
end

function DT.Modules.Register(category, name, adapter)
    category = normalizeCategory(category)
    name = tostring(name or '')
    if category == '' or name == '' or type(adapter) ~= 'table' then return false end

    local providers = DT.Modules._providers[category]
    if not providers then
        providers = {}
        DT.Modules._providers[category] = providers
    end

    adapter.name = adapter.name or name
    adapter.resource = adapter.resource or name
    providers[name] = adapter
    return true
end

function DT.Modules.Get(category, name)
    local providers = DT.Modules._providers[normalizeCategory(category)]
    return providers and providers[name] or nil
end

function DT.Modules.List(category)
    return DT.Modules._providers[normalizeCategory(category)] or {}
end

function DT.Modules.Resolve(category, configured, candidates, aliases, fallback)
    category = normalizeCategory(category)
    configured = tostring(configured or 'auto'):lower()
    aliases = aliases or {}
    configured = aliases[configured] or configured

    local providers = DT.Modules._providers[category] or {}

    local function usable(name)
        local provider = providers[name]
        if not provider then
            for key, candidate in pairs(providers) do
                if tostring(key):lower()==tostring(name):lower() then provider=candidate;break end
            end
        end
        if not provider then return nil end
        if provider.available then
            local ok, result = pcall(provider.available, provider)
            if not ok or result ~= true then return nil end
        elseif provider.resource and provider.resource ~= 'native' and provider.resource ~= 'standalone' and provider.resource ~= 'none' then
            if not DTUtils.isStarted(provider.resource) then return nil end
        end
        return provider
    end

    if configured ~= 'auto' then
        local provider = usable(configured)
        if provider then
            DT.Modules._selected[category] = provider.name
            return provider
        end
    end

    for i = 1, #(candidates or {}) do
        local name = candidates[i]
        local provider = usable(name)
        if provider then
            DT.Modules._selected[category] = name
            return provider
        end
    end

    if fallback then
        local provider = providers[fallback]
        if provider then
            DT.Modules._selected[category] = fallback
            return provider
        end
    end

    DT.Modules._selected[category] = nil
    return nil
end

function DT.Modules.Selected(category)
    return DT.Modules._selected[normalizeCategory(category)]
end

function DT.Modules.Call(adapter, method, ...)
    if type(adapter) ~= 'table' then return nil, 'provider_unavailable' end
    local fn = adapter[method]
    if type(fn) ~= 'function' then return nil, 'unsupported_backend' end
    return fn(adapter, ...)
end
