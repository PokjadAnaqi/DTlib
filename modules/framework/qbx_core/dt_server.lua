local frameworkUtil = DT.FrameworkUtil
local adapter = { resource = 'qbx_core', publicName = 'qbx' }
function adapter:available()
    return DTUtils.isStarted(self.resource)
end
function adapter:getVersion()
    local ok, result = pcall(function()
        return exports.qbx_core:GetCoreVersion(GetCurrentResourceName())
    end)
    return ok and result or frameworkUtil.resourceVersion(self.resource)
end
function adapter:getJobs()
    local ok, result = pcall(function()
        return exports.qbx_core:GetJobs()
    end)
    return ok and result or {}
end
function adapter:getGangs()
    local ok, result = pcall(function()
        return exports.qbx_core:GetGangs()
    end)
    return ok and result or {}
end
function adapter:getJob(name)
    local ok, result = pcall(function()
        return exports.qbx_core:GetJob(name)
    end)
    return ok and result or nil
end
function adapter:getGang(name)
    local ok, result = pcall(function()
        return exports.qbx_core:GetGang(name)
    end)
    return ok and result or nil
end
function adapter:getVehicles(filter)
    local ok, result = pcall(function()
        return exports.qbx_core:GetVehiclesByName(filter)
    end)
    return ok and result or {}
end
function adapter:getWeapons(filter)
    local ok, result = pcall(function()
        return exports.qbx_core:GetWeapons(filter)
    end)
    return ok and result or {}
end
function adapter:getPlayer(source)
    local ok, result = pcall(function()
        return exports.qbx_core:GetPlayer(source)
    end)
    return ok and result or nil
end
function adapter:getByCitizenId(id)
    local ok, result = pcall(function()
        return exports.qbx_core:GetPlayerByCitizenId(id)
    end)
    return ok and result or nil
end
function adapter:getByUserId(id)
    local ok, result = pcall(function()
        return exports.qbx_core:GetPlayerByUserId(id)
    end)
    return ok and result or nil
end
function adapter:getByIdentifier(identifier)
    local ok, playerSource = pcall(function()
        return exports.qbx_core:GetSource(identifier)
    end)
    return ok and tonumber(playerSource) and tonumber(playerSource) > 0 and self:getPlayer(tonumber(playerSource))
        or nil
end
function adapter:getPlayers()
    local out = {}
    local ok, players = pcall(function()
        return exports.qbx_core:GetQBPlayers()
    end)
    if ok and type(players) == 'table' then
        for source in pairs(players) do
            out[#out + 1] = tonumber(source) or source
        end
    end
    return out
end
function adapter:getPlayersData()
    local ok, result = pcall(function()
        return exports.qbx_core:GetPlayersData()
    end)
    return ok and result or {}
end
function adapter:getIdentifier(source)
    local player = self:getPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
end
function adapter:getCitizenId(source)
    return self:getIdentifier(source)
end
function adapter:getUserId(source)
    local id = GetPlayerIdentifierByType(source, 'license')
    if not id then
        return nil
    end
    local ok, result = pcall(function()
        return exports.qbx_core:GetUserId(id)
    end)
    return ok and result ~= 0 and result or nil
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
    local ok, result = pcall(function()
        return exports.qbx_core:GetGroups(source)
    end)
    return ok and result or {}
end
function adapter:hasGroup(source, filter)
    local ok, result = pcall(function()
        return exports.qbx_core:HasGroup(source, filter)
    end)
    return ok and result == true
end
function adapter:hasPrimaryGroup(source, filter)
    local ok, result = pcall(function()
        return exports.qbx_core:HasPrimaryGroup(source, filter)
    end)
    return ok and result == true
end
function adapter:setJob(source, name, grade, onDuty)
    local ok, result = pcall(function()
        return exports.qbx_core:SetJob(source, name, tonumber(grade) or 0)
    end)
    if not ok or result == false then
        return false
    end
    if onDuty ~= nil then
        pcall(function()
            exports.qbx_core:SetJobDuty(source, onDuty == true)
        end)
    end
    return true
end
function adapter:setJobDuty(source, state)
    local ok, result = pcall(function()
        return exports.qbx_core:SetJobDuty(source, state == true)
    end)
    return ok and result ~= false
end
function adapter:setGang(source, name, grade)
    local ok, result = pcall(function()
        return exports.qbx_core:SetGang(source, name, tonumber(grade) or 0)
    end)
    return ok and result ~= false
end
function adapter:getMoney(source, valueType)
    local ok, result = pcall(function()
        return exports.qbx_core:GetMoney(source, valueType or 'cash')
    end)
    return ok and tonumber(result) or 0
end
function adapter:addMoney(source, valueType, provider, result)
    local ok, entryValue = pcall(function()
        return exports.qbx_core:AddMoney(source, valueType or 'cash', provider, result or 'DTlib')
    end)
    return ok and entryValue == true
end
function adapter:removeMoney(source, valueType, provider, result)
    local ok, entryValue = pcall(function()
        return exports.qbx_core:RemoveMoney(source, valueType or 'cash', provider, result or 'DTlib')
    end)
    return ok and entryValue == true
end
function adapter:setMoney(source, valueType, provider, result)
    local ok, entryValue = pcall(function()
        return exports.qbx_core:SetMoney(source, valueType or 'cash', provider, result or 'DTlib')
    end)
    return ok and entryValue == true
end
function adapter:getMeta(source, key)
    local ok, result = pcall(function()
        return exports.qbx_core:GetMetadata(source, key)
    end)
    return ok and result or nil
end
function adapter:setMeta(source, key, value)
    local ok, result = pcall(function()
        return exports.qbx_core:SetMetadata(source, key, value)
    end)
    return ok and result ~= false
end
function adapter:save(source)
    local ok, result = pcall(function()
        return exports.qbx_core:Save(source)
    end)
    return ok and result ~= false
end
function adapter:getData(source)
    local player = self:getPlayer(source)
    return player and player.PlayerData or {}
end
DT.Modules.Register('framework', 'qbx_core', adapter)
