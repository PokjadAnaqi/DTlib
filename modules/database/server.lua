local aliases = { ox = 'oxmysql' }
local function resolveAdapter()
    return DT.Modules.Resolve('database', DTConfig.Adapters.database, { 'oxmysql', 'ghmattimysql' }, aliases, 'none')
end
local function call(method, ...)
    local adapter = resolveAdapter()
    if not adapter or adapter.resource == 'none' then
        error(
            ('DT.Database.%s: no supported database backend is running (configured=%s, oxmysql=%s, ghmattimysql=%s). Start a supported driver before DTlib, for example ensure oxmysql; inspect the driver startup log if it is not started.'):format(
                method,
                tostring(DTConfig.Adapters.database),
                GetResourceState('oxmysql'),
                GetResourceState('ghmattimysql')
            ),
            3
        )
    end
    local handler = adapter[method]
    if type(handler) ~= 'function' then
        return nil, 'unsupported_backend'
    end
    return handler(adapter, ...)
end
function DT.Database.Name()
    local adapter = resolveAdapter()
    return adapter and adapter.publicName or 'none'
end
function DT.Database.Available()
    local adapter = resolveAdapter()
    return adapter and adapter.resource ~= 'none'
end
function DT.Database.Query(query, payload)
    return call('query', query, payload or {})
end
DT.Database.Execute = DT.Database.Query
function DT.Database.Single(query, payload)
    local adapter = resolveAdapter()
    if adapter and adapter.single then
        return adapter:single(query, payload or {})
    end
    local rows = DT.Database.Query(query, payload)
    return rows and rows[1] or nil
end
function DT.Database.Scalar(query, payload)
    local adapter = resolveAdapter()
    if adapter and adapter.scalar then
        return adapter:scalar(query, payload or {})
    end
    local row = DT.Database.Single(query, payload)
    if type(row) ~= 'table' then
        return row
    end
    for _, entry in pairs(row) do
        return entry
    end
end
function DT.Database.Insert(query, payload)
    local adapter = resolveAdapter()
    if adapter and adapter.insert then
        return adapter:insert(query, payload or {})
    end
    local response = DT.Database.Query(query, payload)
    return response and (response.insertId or response.insert_id)
end
function DT.Database.Update(query, payload)
    local adapter = resolveAdapter()
    if adapter and adapter.update then
        return adapter:update(query, payload or {})
    end
    local response = DT.Database.Query(query, payload)
    return response and (response.affectedRows or response.changedRows) or 0
end
function DT.Database.Prepare(query, payload)
    local adapter = resolveAdapter()
    if adapter and adapter.prepare then
        return adapter:prepare(query, payload or {})
    end
    return DT.Database.Query(query, payload)
end
function DT.Database.RawExecute(query, payload)
    local adapter = resolveAdapter()
    if adapter and adapter.rawExecute then
        return adapter:rawExecute(query, payload or {})
    end
    return DT.Database.Query(query, payload)
end
function DT.Database.Transaction(query, payload)
    return call('transaction', query, payload)
end
DT.Database.query = DT.Database.Query
DT.Database.execute = DT.Database.Query
DT.Database.single = DT.Database.Single
DT.Database.scalar = DT.Database.Scalar
DT.Database.insert = DT.Database.Insert
DT.Database.update = DT.Database.Update
DT.Database.prepare = DT.Database.Prepare
DT.Database.rawExecute = DT.Database.RawExecute
DT.Database.transaction = DT.Database.Transaction

function DT.Database.Status()
    return {
        configured = DTConfig.Adapters.database,
        provider = DT.Database.Name(),
        resources = { oxmysql = GetResourceState('oxmysql'), ghmattimysql = GetResourceState('ghmattimysql') },
    }
end

-- A running driver is not necessarily connected. Probe it without blocking the caller forever.
function DT.Database.AwaitReady(timeoutMs)
    timeoutMs = tonumber(timeoutMs) or 10000
    if timeoutMs ~= timeoutMs or timeoutMs < 0 or timeoutMs == math.huge then
        return false, 'invalid_timeout'
    end
    local deadline = GetGameTimer() + math.min(timeoutMs, 60000)
    while not DT.Database.Available() do
        if GetGameTimer() >= deadline then
            return false, 'database_timeout'
        end
        Wait(50)
    end
    local waiter = promise.new()
    local settled = false
    local function finish(ok, errorMessage)
        if settled then
            return
        end
        settled = true
        waiter:resolve({ ok = ok, error = errorMessage })
    end
    SetTimeout(math.max(0, deadline - GetGameTimer()), function()
        finish(false, 'database_timeout')
    end)
    CreateThread(function()
        local ok, value = pcall(DT.Database.Scalar, 'SELECT 1', {})
        finish(
            ok and tonumber(value) == 1,
            not ok and 'database_unavailable' or tonumber(value) ~= 1 and 'database_not_ready' or nil
        )
    end)
    local result = Citizen.Await(waiter)
    return result.ok, result.error
end
