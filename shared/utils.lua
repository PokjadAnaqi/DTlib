DTUtils = DTUtils or {}

function DTUtils.copy(value)
    if type(value) ~= 'table' then return value end
    local out = {}
    for k, v in pairs(value) do out[DTUtils.copy(k)] = DTUtils.copy(v) end
    return out
end

function DTUtils.merge(base, extra)
    local out = DTUtils.copy(base or {})
    for k, v in pairs(extra or {}) do
        if type(v) == 'table' and type(out[k]) == 'table' then
            out[k] = DTUtils.merge(out[k], v)
        else
            out[k] = DTUtils.copy(v)
        end
    end
    return out
end

function DTUtils.clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

function DTUtils.trim(value)
    if type(value) ~= 'string' then return value end
    return value:match('^%s*(.-)%s*$')
end

function DTUtils.isStarted(resource)
    return resource and GetResourceState(resource) == 'started'
end

function DTUtils.detect(preferred, candidates)
    if preferred and preferred ~= '' and preferred ~= 'auto' then
        return DTUtils.isStarted(preferred) and preferred or nil
    end
    for i = 1, #candidates do
        if DTUtils.isStarted(candidates[i]) then return candidates[i] end
    end
end

function DTUtils.isFunctionRef(value)
    return type(value) == 'table' and rawget(value, '__cfx_functionReference') ~= nil
end

function DTUtils.isCallable(value)
    if type(value) == 'function' or DTUtils.isFunctionRef(value) then return true end
    if type(value) ~= 'table' then return false end
    local mt = getmetatable(value)
    return mt ~= nil and type(mt.__call) == 'function'
end

function DTUtils.wrapCallable(value)
    if type(value) == 'function' then return value end
    if not DTUtils.isCallable(value) then return nil end

    -- Cfx exports marshal cross-resource functions as callable function refs.
    -- Wrap them in a local Lua closure so pcall/table storage behaves consistently.
    return function(...)
        return value(...)
    end
end

function DTUtils.safeCall(fn, ...)
    fn = DTUtils.wrapCallable(fn)
    if not fn then return false, 'value is not callable' end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return false, a end
    return true, a, b, c, d
end

function DTUtils.tableContains(tbl, value)
    for _, entry in pairs(tbl or {}) do
        if entry == value then return true end
    end
    return false
end
