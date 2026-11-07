local frameworkUtil = DT.FrameworkUtil
local candidates = { 'qbx_core', 'qb-core', 'es_extended', 'ox_core' }
local function resolveAdapter()
    return DT.Modules.Resolve('framework', DTConfig.Adapters.framework, candidates, frameworkUtil.aliases, 'standalone')
end
local function call(method, ...)
    local adapter = resolveAdapter()
    if not adapter or type(adapter[method]) ~= 'function' then
        return nil, 'unsupported_backend'
    end
    return adapter[method](adapter, ...)
end
function DT.Framework.Name()
    local adapter = resolveAdapter()
    return adapter and adapter.publicName or 'standalone'
end
function DT.Framework.Resource()
    local adapter = resolveAdapter()
    return adapter and adapter.resource ~= 'standalone' and adapter.resource or nil
end
function DT.Framework.IsAdmin(source)
    return call('isAdmin', source) == true
end
function DT.Framework.Available(name)
    if not name then
        return DT.Framework.Resource() ~= nil
    end
    name = tostring(name):lower()
    name = frameworkUtil.aliases[name] or name
    return DTUtils.isStarted(name)
end
function DT.Framework.GetVersion()
    local adapter = resolveAdapter()
    if not adapter or adapter.resource == 'standalone' then
        return nil
    end
    return adapter.getVersion and adapter:getVersion() or frameworkUtil.resourceVersion(adapter.resource)
end
function DT.Framework.GetJobs()
    return call('getJobs') or {}
end
function DT.Framework.GetGangs()
    return call('getGangs') or {}
end
function DT.Framework.GetJob(name)
    if not name then
        return nil
    end
    local result = call('getJob', name)
    if result ~= nil then
        return result
    end
    return DT.Framework.GetJobs()[name]
end
function DT.Framework.GetGang(name)
    if not name then
        return nil
    end
    local result = call('getGang', name)
    if result ~= nil then
        return result
    end
    return DT.Framework.GetGangs()[name]
end
function DT.Framework.GetVehicles(filter)
    return call('getVehicles', filter) or {}
end
function DT.Framework.GetWeapons(filter)
    return call('getWeapons', filter) or {}
end
function DT.Player.Get(source)
    return call('getPlayer', source)
end
function DT.Player.GetByCitizenId(id)
    return call('getByCitizenId', id)
end
function DT.Player.GetByUserId(id)
    return call('getByUserId', id)
end
function DT.Player.GetByCharacterId(id)
    return call('getByCharacterId', id)
end
function DT.Player.GetByIdentifier(id)
    return call('getByIdentifier', id)
end
function DT.Player.GetPlayers()
    local result = call('getPlayers')
    if type(result) == 'table' and #result > 0 then
        return result
    end
    local output = {}
    for _, sourceId in ipairs(GetPlayers()) do
        output[#output + 1] = tonumber(sourceId) or sourceId
    end
    return output
end
function DT.Player.GetPlayersData()
    local result = call('getPlayersData')
    if type(result) == 'table' then
        return result
    end
    local output = {}
    for _, sourceId in ipairs(DT.Player.GetPlayers()) do
        local data = DT.Player.GetData(sourceId)
        if data then
            output[#output + 1] = data
        end
    end
    return output
end
function DT.Player.GetIdentifiers(source)
    return frameworkUtil.playerIdentifiers(source)
end
function DT.Player.GetIdentifierByType(source, valueType)
    valueType = valueType or 'license'
    local ok, result = pcall(GetPlayerIdentifierByType, source, valueType)
    return ok and result or DT.Player.GetIdentifiers(source)[valueType]
end
function DT.Player.GetLicenseIdentifier(source)
    return DT.Player.GetIdentifierByType(source, 'license2') or DT.Player.GetIdentifierByType(source, 'license')
end
function DT.Player.GetIdentifier(source)
    return call('getIdentifier', source) or DT.Player.GetIdentifierByType(source, 'license')
end
function DT.Player.GetCitizenId(source)
    return call('getCitizenId', source)
end
function DT.Player.GetUserId(source)
    return call('getUserId', source)
end
function DT.Player.GetCharacterId(source)
    return call('getCharacterId', source)
end
function DT.Player.GetStateId(source)
    return call('getStateId', source)
end
function DT.Player.GetName(source)
    return call('getName', source) or GetPlayerName(source)
end
function DT.Player.GetJob(source)
    return call('getJobFor', source)
end
function DT.Player.GetGang(source)
    return call('getGangFor', source)
end
function DT.Player.GetGroups(source)
    return call('getGroups', source) or {}
end
function DT.Player.GetGroup(source, filter)
    local result, secondary = call('getGroup', source, filter)
    if result ~= nil then
        return result, secondary
    end
    local groups = DT.Player.GetGroups(source)
    if type(filter) == 'string' then
        return groups[filter]
    end
    for name, grade in pairs(groups) do
        if frameworkUtil.filterMatch({ [name] = grade }, filter) then
            return name, grade
        end
    end
end
function DT.Player.HasGroup(source, filter)
    local result = call('hasGroup', source, filter)
    if result ~= nil and result ~= 'unsupported_backend' then
        return result == true
    end
    return frameworkUtil.filterMatch(DT.Player.GetGroups(source), filter)
end
function DT.Player.HasPrimaryGroup(source, filter)
    local result = call('hasPrimaryGroup', source, filter)
    if result ~= nil and result ~= 'unsupported_backend' then
        return result == true
    end
    local groups = {}
    local job, adapter = DT.Player.GetJob(source), DT.Player.GetGang(source)
    if job and job.name then
        groups[job.name] = job.grade
    end
    if adapter and adapter.name then
        groups[adapter.name] = adapter.grade
    end
    return frameworkUtil.filterMatch(groups, filter)
end
function DT.Player.SetJob(source, name, grade, onDuty)
    return call('setJob', source, name, grade, onDuty) == true
end
function DT.Player.SetJobDuty(source, state)
    return call('setJobDuty', source, state) == true
end
function DT.Player.SetGang(source, name, grade)
    return call('setGang', source, name, grade) == true
end
function DT.Player.GetMoney(source, valueType)
    return tonumber(call('getMoney', source, valueType) or 0) or 0
end
function DT.Player.AddMoney(source, valueType, adapter, result)
    adapter = tonumber(adapter) or 0
    if adapter <= 0 then
        return false
    end
    return call('addMoney', source, valueType, adapter, result) == true
end
function DT.Player.RemoveMoney(source, valueType, adapter, result)
    adapter = tonumber(adapter) or 0
    if adapter <= 0 then
        return false
    end
    return call('removeMoney', source, valueType, adapter, result) == true
end
function DT.Player.SetMoney(source, valueType, adapter, result)
    adapter = math.max(0, tonumber(adapter) or 0)
    return call('setMoney', source, valueType, adapter, result) == true
end
function DT.Player.GetMeta(source, key)
    return call('getMeta', source, key)
end
function DT.Player.SetMeta(source, key, value, replicated)
    return call('setMeta', source, key, value, replicated) == true
end
function DT.Player.GetStatus(source, key)
    return call('getStatus', source, key)
end
function DT.Player.SetStatus(source, key, result)
    return call('setStatus', source, key, result) == true
end
function DT.Player.AddStatus(source, key, result)
    return call('addStatus', source, key, result) == true
end
function DT.Player.RemoveStatus(source, key, result)
    return call('removeStatus', source, key, result) == true
end
function DT.Player.HasPermission(source, payload)
    local result = call('hasPermission', source, payload)
    if result ~= nil and result ~= 'unsupported_backend' then
        return result == true
    end
    return IsPlayerAceAllowed(source, payload)
end
function DT.Player.GetCoords(source)
    local result = call('getCoords', source)
    if result then
        return result
    end
    local ped = GetPlayerPed(source)
    return ped and ped ~= 0 and GetEntityCoords(ped) or nil
end
function DT.Player.Save(source)
    return call('save', source) == true
end
function DT.Player.GetData(source)
    return call('getData', source) or {}
end
DT.Callback.Register('DTlib:internal:getPlayerData', function(source)
    return DT.Player.GetData(source)
end)
