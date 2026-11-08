local frameworkUtil = DT.FrameworkUtil
local adapter = { resource = 'es_extended', publicName = 'esx' }
local function core()
    local ok, result = pcall(function()
        return exports.es_extended:getSharedObject()
    end)
    return ok and result or nil
end
local function player(source)
    local coreObject = core()
    if not coreObject then
        return nil
    end
    if type(coreObject.Player) == 'function' then
        local ok, payload = pcall(coreObject.Player, source)
        if ok and payload then
            return payload
        end
    end
    if type(coreObject.GetPlayerFromId) == 'function' then
        local ok, payload = pcall(coreObject.GetPlayerFromId, source)
        if ok then
            return payload
        end
    end
end
local function account(valueType)
    return (valueType == nil or valueType == 'cash') and 'money' or valueType
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:isAdmin(source)
    local playerObject = player(source)
    if not playerObject or not playerObject.getGroup then
        return false
    end
    local ok, group = pcall(playerObject.getGroup)
    return ok and (group == 'admin' or group == 'superadmin')
end
function adapter:getJobs()
    local coreObject = core()
    if coreObject and type(coreObject.GetJobs) == 'function' then
        local ok, result = pcall(coreObject.GetJobs)
        return ok and result or {}
    end
    return {}
end
function adapter:getGangs()
    return {}
end
function adapter:getJob(name)
    return self:getJobs()[name]
end
function adapter:getGang()
    return nil
end
function adapter:getPlayer(source)
    return player(source)
end
function adapter:getByIdentifier(identifier)
    local coreObject = core()
    if not coreObject then
        return nil
    end
    if type(coreObject.Player) == 'function' then
        local ok, payload = pcall(coreObject.Player, identifier)
        if ok and payload then
            return payload
        end
    end
    if type(coreObject.GetPlayerFromIdentifier) == 'function' then
        local ok, payload = pcall(coreObject.GetPlayerFromIdentifier, identifier)
        if ok then
            return payload
        end
    end
end
function adapter:getPlayers()
    local coreObject = core()
    if coreObject and type(coreObject.ExtendedPlayers) == 'function' then
        local ok, result = pcall(coreObject.ExtendedPlayers)
        if ok and type(result) == 'table' then
            local output = {}
            for index = 1, #result do
                local sourceId = result[index].source or result[index].playerId
                if sourceId then
                    output[#output + 1] = tonumber(sourceId) or sourceId
                end
            end
            if #output > 0 then
                return output
            end
        end
    end
    if coreObject and type(coreObject.GetPlayers) == 'function' then
        local ok, result = pcall(coreObject.GetPlayers)
        if ok and result then
            return result
        end
    end
    return {}
end
function adapter:getIdentifier(source)
    local playerObject = player(source)
    if playerObject and playerObject.getIdentifier then
        local ok, result = pcall(playerObject.getIdentifier)
        if ok and result then
            return result
        end
    end
    return playerObject and playerObject.identifier or GetPlayerIdentifierByType(source, 'license')
end
function adapter:getName(source)
    local playerObject = player(source)
    if playerObject and playerObject.getName then
        local ok, result = pcall(playerObject.getName)
        if ok and result then
            return result
        end
    end
    return playerObject and playerObject.name or GetPlayerName(source)
end
function adapter:getJobFor(source)
    local playerObject = player(source)
    if not playerObject then
        return nil
    end
    local data = playerObject.job
    if playerObject.getJob then
        local ok, result = pcall(playerObject.getJob)
        if ok and result then
            data = result
        end
    end
    return frameworkUtil.normalizeGroup(data)
end
function adapter:getGangFor()
    return nil
end
function adapter:getGroups(source)
    local groups = {}
    local job = self:getJobFor(source)
    if job and job.name then
        groups[job.name] = job.grade
    end
    local playerObject = player(source)
    if playerObject and playerObject.getGroup then
        local ok, result = pcall(playerObject.getGroup)
        if ok and result then
            groups[result] = math.max(groups[result] or 0, 0)
        end
    end
    return groups
end
function adapter:setJob(source, name, grade, onDuty)
    local playerObject = player(source)
    if not playerObject or not playerObject.setJob then
        return false
    end
    playerObject.setJob(name, tonumber(grade) or 0, onDuty)
    return true
end
function adapter:getMoney(source, valueType)
    local playerObject = player(source)
    if playerObject and playerObject.getAccount then
        local ok, provider = pcall(playerObject.getAccount, account(valueType))
        return ok and provider and tonumber(provider.money) or 0
    end
    return 0
end
function adapter:addMoney(source, valueType, provider, result)
    local playerObject = player(source)
    if playerObject and playerObject.addAccountMoney then
        playerObject.addAccountMoney(account(valueType), provider, result or 'DTlib')
        return true
    end
    return false
end
function adapter:removeMoney(source, valueType, provider, result)
    local playerObject = player(source)
    if playerObject and playerObject.removeAccountMoney then
        playerObject.removeAccountMoney(account(valueType), provider, result or 'DTlib')
        return true
    end
    return false
end
function adapter:setMoney(source, valueType, provider, result)
    local playerObject = player(source)
    if playerObject and playerObject.setAccountMoney then
        playerObject.setAccountMoney(account(valueType), provider, result or 'DTlib')
        return true
    end
    return false
end
function adapter:getMeta(source, key)
    local playerObject = player(source)
    if playerObject and playerObject.getMeta then
        local ok, result = pcall(playerObject.getMeta, key)
        return ok and result or nil
    end
end
function adapter:setMeta(source, key, value)
    local playerObject = player(source)
    if playerObject and playerObject.setMeta then
        playerObject.setMeta(key, value)
        return true
    end
    return false
end
function adapter:getCoords(source)
    local playerObject = player(source)
    if playerObject and playerObject.getCoords then
        local ok, result = pcall(playerObject.getCoords, true)
        if ok and result then
            return result
        end
    end
end
function adapter:save(source)
    local playerObject = player(source)
    if playerObject and playerObject.save then
        playerObject.save()
        return true
    end
    return false
end
function adapter:getData(source)
    local playerObject = player(source)
    if not playerObject then
        return {}
    end
    return {
        source = tonumber(source) or source,
        identifier = self:getIdentifier(source),
        name = self:getName(source),
        job = self:getJobFor(source),
        groups = self:getGroups(source),
        accounts = playerObject.getAccounts and playerObject.getAccounts() or playerObject.accounts,
        metadata = playerObject.getMeta and playerObject.getMeta() or nil,
    }
end
DT.Modules.Register('framework', 'es_extended', adapter)
