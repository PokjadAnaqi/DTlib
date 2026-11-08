local frameworkUtil = DT.FrameworkUtil
local adapter = { resource = 'qb-core', publicName = 'qb' }
local function core()
    local ok, result = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    return ok and result or nil
end
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:isAdmin(source)
    local coreObject = core()
    local hasPermission = coreObject and coreObject.Functions and coreObject.Functions.HasPermission
    if not hasPermission then
        return false
    end
    local ok, allowed = pcall(hasPermission, source, 'admin')
    return ok and allowed == true
end
function adapter:getJobs()
    local coreObject = core()
    return coreObject and coreObject.Shared and coreObject.Shared.Jobs or {}
end
function adapter:getGangs()
    local coreObject = core()
    return coreObject and coreObject.Shared and coreObject.Shared.Gangs or {}
end
function adapter:getJob(name)
    return self:getJobs()[name]
end
function adapter:getGang(name)
    return self:getGangs()[name]
end
function adapter:getVehicles(filter)
    local coreObject = core()
    local result = coreObject and coreObject.Shared and coreObject.Shared.Vehicles or {}
    return filter and result[filter] or result
end
function adapter:getWeapons(filter)
    local coreObject = core()
    local result = coreObject and coreObject.Shared and coreObject.Shared.Weapons or {}
    return filter and result[filter] or result
end
function adapter:getPlayer(source)
    local coreObject = core()
    return coreObject and coreObject.Functions.GetPlayer(source) or nil
end
function adapter:getByCitizenId(id)
    local coreObject = core()
    return coreObject and coreObject.Functions.GetPlayerByCitizenId and coreObject.Functions.GetPlayerByCitizenId(id)
        or nil
end
function adapter:getPlayers()
    local coreObject = core()
    return coreObject and coreObject.Functions.GetPlayers and coreObject.Functions.GetPlayers() or {}
end
function adapter:getIdentifier(source)
    local player = self:getPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end
function adapter:getCitizenId(source)
    return self:getIdentifier(source)
end
function adapter:getName(source)
    local player = self:getPlayer(source)
    if not player or not player.PlayerData then
        return GetPlayerName(source)
    end
    local character = player.PlayerData.charinfo or {}
    local count = DTUtils.trim(('%s %s'):format(character.firstname or '', character.lastname or ''))
    return count ~= '' and count or player.PlayerData.name or GetPlayerName(source)
end
function adapter:getJobFor(source)
    local player = self:getPlayer(source)
    return player and frameworkUtil.normalizeGroup(player.PlayerData and player.PlayerData.job) or nil
end
function adapter:getGangFor(source)
    local player = self:getPlayer(source)
    return player and frameworkUtil.normalizeGroup(player.PlayerData and player.PlayerData.gang) or nil
end
function adapter:getGroups(source)
    local groups = {}
    local job = self:getJobFor(source)
    local gang = self:getGangFor(source)
    if job and job.name then
        groups[job.name] = job.grade
    end
    if gang and gang.name then
        groups[gang.name] = gang.grade
    end
    return groups
end
function adapter:setJob(source, name, grade, onDuty)
    local player = self:getPlayer(source)
    if not player or not player.Functions or not player.Functions.SetJob then
        return false
    end
    local result = player.Functions.SetJob(name, tonumber(grade) or 0)
    if onDuty ~= nil and player.Functions.SetJobDuty then
        player.Functions.SetJobDuty(onDuty == true)
    end
    return result ~= false
end
function adapter:setJobDuty(source, state)
    local player = self:getPlayer(source)
    return player
            and player.Functions
            and player.Functions.SetJobDuty
            and player.Functions.SetJobDuty(state == true) ~= false
        or false
end
function adapter:setGang(source, name, grade)
    local player = self:getPlayer(source)
    return player
            and player.Functions
            and player.Functions.SetGang
            and player.Functions.SetGang(name, tonumber(grade) or 0) ~= false
        or false
end
function adapter:getMoney(source, valueType)
    local player = self:getPlayer(source)
    return player
            and player.PlayerData
            and player.PlayerData.money
            and tonumber(player.PlayerData.money[valueType or 'cash'])
        or 0
end
function adapter:addMoney(source, valueType, provider, result)
    local player = self:getPlayer(source)
    return player
            and player.Functions
            and player.Functions.AddMoney
            and player.Functions.AddMoney(valueType or 'cash', provider, result or 'DTlib') ~= false
        or false
end
function adapter:removeMoney(source, valueType, provider, result)
    local player = self:getPlayer(source)
    return player
            and player.Functions
            and player.Functions.RemoveMoney
            and player.Functions.RemoveMoney(valueType or 'cash', provider, result or 'DTlib') ~= false
        or false
end
function adapter:setMoney(source, valueType, provider, result)
    local player = self:getPlayer(source)
    return player
            and player.Functions
            and player.Functions.SetMoney
            and player.Functions.SetMoney(valueType or 'cash', provider, result or 'DTlib') ~= false
        or false
end
function adapter:getMeta(source, key)
    local player = self:getPlayer(source)
    return player and player.PlayerData and player.PlayerData.metadata and player.PlayerData.metadata[key] or nil
end
function adapter:setMeta(source, key, value)
    local player = self:getPlayer(source)
    if player and player.Functions and player.Functions.SetMetaData then
        player.Functions.SetMetaData(key, value)
        return true
    end
    return false
end
function adapter:save(source)
    local player = self:getPlayer(source)
    if player and player.Functions and player.Functions.Save then
        player.Functions.Save()
        return true
    end
    return false
end
function adapter:getData(source)
    local player = self:getPlayer(source)
    return player and player.PlayerData or {}
end
DT.Modules.Register('framework', 'qb-core', adapter)
