local frameworkUtil = DT.FrameworkUtil
local adapter = { resource = 'ox_core', publicName = 'ox' }
local function pcallExport(handler)
    local ok, provider, secondary, coreObject = pcall(handler)
    if not ok then
        return nil
    end
    return provider, secondary, coreObject
end
local function call(source, method, ...)
    local arguments = { ... }
    return pcallExport(function()
        return exports.ox_core:CallPlayer(source, method, table.unpack(arguments))
    end)
end
local function pair(source, method, ...)
    local result, secondary = call(source, method, ...)
    if type(result) == 'table' and secondary == nil then
        return result[1], result[2]
    end
    return result, secondary
end
local function groupDef(name)
    return name and GlobalState[('group.%s'):format(name)] or nil
end
local function player(source)
    return pcallExport(function()
        return exports.ox_core:GetPlayer(source)
    end)
end
local function accountFor(source)
    local playerObject = player(source)
    if not playerObject or not playerObject.charId then
        return nil
    end
    return pcallExport(function()
        return exports.ox_core:GetCharacterAccount(playerObject.charId)
    end)
end
local function accountCall(id, method, ...)
    if not id then
        return nil
    end
    local arguments = { ... }
    return pcallExport(function()
        return exports.ox_core:CallAccount(id, method, table.unpack(arguments))
    end)
end
local function cashCount(source)
    if not DTUtils.isStarted('ox_inventory') then
        return 0
    end
    local ok, result = pcall(function()
        return exports.ox_inventory:GetItemCount(source, 'money')
    end)
    return ok and tonumber(result) or 0
end
local function cashAdd(source, provider)
    if not DTUtils.isStarted('ox_inventory') then
        return false
    end
    local ok, result = pcall(function()
        return exports.ox_inventory:AddItem(source, 'money', provider)
    end)
    return ok and result == true
end
local function cashRemove(source, provider)
    if not DTUtils.isStarted('ox_inventory') then
        return false
    end
    local ok, result = pcall(function()
        return exports.ox_inventory:RemoveItem(source, 'money', provider)
    end)
    return ok and result == true
end
local function cashSet(source, provider)
    if not DTUtils.isStarted('ox_inventory') then
        return false
    end
    local ok, result = pcall(function()
        return exports.ox_inventory:SetItem(source, 'money', provider)
    end)
    return ok and result ~= false
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:getJobs()
    local ok, count = pcall(function()
        return exports.ox_core:GetGroupsByType('job')
    end)
    local out = {}
    if ok and type(count) == 'table' then
        for index = 1, #count do
            out[count[index]] = groupDef(count[index]) or { name = count[index], type = 'job' }
        end
    end
    return out
end
function adapter:getGangs()
    local ok, count = pcall(function()
        return exports.ox_core:GetGroupsByType('gang')
    end)
    local out = {}
    if ok and type(count) == 'table' then
        for index = 1, #count do
            out[count[index]] = groupDef(count[index]) or { name = count[index], type = 'gang' }
        end
    end
    return out
end
function adapter:getJob(name)
    return self:getJobs()[name]
end
function adapter:getGang(name)
    return self:getGangs()[name]
end
function adapter:getVehicles(filter)
    local ok, result = pcall(function()
        return exports.ox_core:GetVehicleData(filter)
    end)
    return ok and result or {}
end
function adapter:getWeapons()
    return {}
end
function adapter:getPlayer(source)
    return player(source)
end
function adapter:getByUserId(id)
    return pcallExport(function()
        return exports.ox_core:GetPlayerFromUserId(id)
    end)
end
function adapter:getByCharacterId(id)
    return pcallExport(function()
        return exports.ox_core:GetPlayerFromCharId(id)
    end)
end
function adapter:getByIdentifier(identifier)
    return pcallExport(function()
        return exports.ox_core:GetPlayerFromFilter({ identifier = identifier })
    end)
end
function adapter:getPlayers()
    local result = pcallExport(function()
        return exports.ox_core:GetPlayers()
    end) or {}
    local out = {}
    for index = 1, #result do
        if result[index].source then
            out[#out + 1] = tonumber(result[index].source) or result[index].source
        end
    end
    return out
end
function adapter:getPlayersData()
    return pcallExport(function()
        return exports.ox_core:GetPlayers()
    end) or {}
end
function adapter:getIdentifier(source)
    local playerObject = player(source)
    return playerObject and (playerObject.stateId or playerObject.identifier)
        or GetPlayerIdentifierByType(source, 'license')
end
function adapter:getUserId(source)
    local playerObject = player(source)
    return playerObject and playerObject.userId or nil
end
function adapter:getCharacterId(source)
    local playerObject = player(source)
    return playerObject and playerObject.charId or nil
end
function adapter:getStateId(source)
    local playerObject = player(source)
    return playerObject and playerObject.stateId or nil
end
function adapter:getName(source)
    local playerObject = player(source)
    return call(source, 'get', 'name') or (playerObject and playerObject.username) or GetPlayerName(source)
end
function adapter:getJobFor(source)
    local count, groups = pair(source, 'getGroupByType', 'job')
    return count and frameworkUtil.normalizeGroup(groupDef(count), count, groups) or nil
end
function adapter:getGangFor(source)
    local count, groups = pair(source, 'getGroupByType', 'gang')
    return count and frameworkUtil.normalizeGroup(groupDef(count), count, groups) or nil
end
function adapter:getGroups(source)
    local result = call(source, 'getGroups')
    return type(result) == 'table' and result or {}
end
function adapter:getGroup(source, filter)
    return pair(source, 'getGroup', filter)
end
function adapter:hasGroup(source, filter)
    local count = self:getGroup(source, filter)
    return count ~= nil and count ~= false
end
function adapter:hasPrimaryGroup(source, filter)
    local active = call(source, 'get', 'activeGroup')
    if not active then
        return false
    end
    local groups = self:getGroups(source)
    return frameworkUtil.filterMatch({ [active] = groups[active] or 0 }, filter)
end
function adapter:setJob(source, name, grade)
    local current = select(1, pair(source, 'getGroupByType', 'job'))
    if current and current ~= name then
        call(source, 'setGroup', current, 0)
    end
    return call(source, 'setGroup', name, tonumber(grade) or 0) == true
end
function adapter:setJobDuty()
    return false
end
function adapter:setGang(source, name, grade)
    local current = select(1, pair(source, 'getGroupByType', 'gang'))
    if current and current ~= name then
        call(source, 'setGroup', current, 0)
    end
    return call(source, 'setGroup', name, tonumber(grade) or 0) == true
end
function adapter:getMoney(source, valueType)
    valueType = valueType or 'cash'
    if valueType == 'cash' or valueType == 'money' then
        return cashCount(source)
    end
    if valueType == 'bank' then
        local provider = accountFor(source)
        local secondary = provider and accountCall(provider.accountId, 'get', 'balance')
        return tonumber(secondary) or 0
    end
    return 0
end
function adapter:addMoney(source, valueType, provider, result)
    valueType = valueType or 'cash'
    if valueType == 'cash' or valueType == 'money' then
        return cashAdd(source, provider)
    end
    if valueType == 'bank' then
        local x = accountFor(source)
        local entryValue = x
            and accountCall(x.accountId, 'addBalance', { amount = provider, message = result or 'DTlib' })
        return type(entryValue) == 'table' and entryValue.success == true or entryValue == true
    end
    return false
end
function adapter:removeMoney(source, valueType, provider, result)
    valueType = valueType or 'cash'
    if valueType == 'cash' or valueType == 'money' then
        return cashRemove(source, provider)
    end
    if valueType == 'bank' then
        local x = accountFor(source)
        local entryValue = x
            and accountCall(x.accountId, 'removeBalance', { amount = provider, message = result or 'DTlib' })
        return type(entryValue) == 'table' and entryValue.success == true or entryValue == true
    end
    return false
end
function adapter:setMoney(source, valueType, provider, result)
    valueType = valueType or 'cash'
    if valueType == 'cash' or valueType == 'money' then
        return cashSet(source, provider)
    end
    if valueType == 'bank' then
        local coreObject = self:getMoney(source, 'bank')
        if coreObject == provider then
            return true
        elseif provider > coreObject then
            return self:addMoney(source, 'bank', provider - coreObject, result)
        else
            return self:removeMoney(source, 'bank', coreObject - provider, result)
        end
    end
    return false
end
function adapter:getMeta(source, key)
    return call(source, 'get', key)
end
function adapter:setMeta(source, key, value, replicated)
    call(source, 'set', key, value, replicated == true)
    return true
end
function adapter:getStatus(source, key)
    return call(source, 'getStatus', key)
end
function adapter:setStatus(source, key, result)
    return call(source, 'setStatus', key, result) == true
end
function adapter:addStatus(source, key, result)
    return call(source, 'addStatus', key, result) == true
end
function adapter:removeStatus(source, key, result)
    return call(source, 'removeStatus', key, result) == true
end
function adapter:hasPermission(source, payload)
    local result = call(source, 'hasPermission', payload)
    return result == true
end
function adapter:getCoords(source)
    return call(source, 'getCoords')
end
function adapter:save(source)
    call(source, 'save')
    return true
end
function adapter:getData(source)
    local playerObject = player(source)
    if not playerObject then
        return {}
    end
    return {
        source = tonumber(source) or source,
        identifier = playerObject.identifier,
        userId = playerObject.userId,
        charId = playerObject.charId,
        stateId = playerObject.stateId,
        name = self:getName(source),
        job = self:getJobFor(source),
        gang = self:getGangFor(source),
        groups = self:getGroups(source),
        activeGroup = self:getMeta(source, 'activeGroup'),
    }
end
DT.Modules.Register('framework', 'ox_core', adapter)
