local providerRegistry = DT.Providers
local config, experience = {}, {}
local spec = {
    evolent_skills = { 'getSkillLevel', 'addXp', 'removeXp' },
    OT_skills = { 'getSkill', 'addXP', 'removeXP' },
    pickle_xp = { 'GetPlayerLevel', 'AddPlayerXP', 'RemovePlayerXP' },
}
local function create(name, maxLevel, base, scale)
    assert(type(name) == 'string' and name ~= '', 'invalid_skill')
    config[name] = {
        maxLevel = math.max(1, tonumber(maxLevel) or 99),
        base = math.max(1, tonumber(base) or 50),
        scale = math.max(1, tonumber(scale) or 1.1),
    }
    return config[name]
end
local function threshold(name, level)
    local coreObject = config[name] or create(name)
    local xp = 0
    for index = 1, math.max(0, math.min(coreObject.maxLevel, tonumber(level) or 1) - 1) do
        xp = xp + math.floor(coreObject.base * coreObject.scale ^ (index - 1))
    end
    return xp
end
for _, definition in ipairs(DTEcosystemCatalog.skills.providers) do
    providerRegistry.Register('skills', definition.resource, function(resource)
        local api = { Create = create, GetXPForLevel = threshold, GetXPRequiredForLevel = threshold }
        if not providerRegistry.Server then
            function api.GetSkillLevel(name)
                return DT.Callback.Await('DTlib:provider:skillLevel', resource, name)
            end
            if resource == 'native' then
                function api.GetXP(name)
                    return DT.Callback.Await('DTlib:provider:skillXP', name)
                end
            end
            return api
        end
        local vendor = spec[resource]
        if vendor then
            function api.GetSkillLevel(playerSource, name)
                local value = providerRegistry.Export(resource, vendor[1], playerSource, name)
                return type(value) == 'table' and value.level or value
            end
            api.AddXp = providerRegistry.Bind(resource, vendor[2])
            api.RemoveXp = providerRegistry.Bind(resource, vendor[3])
            api.AddXP = api.AddXp
        else
            function api.GetXP(playerSource, name)
                return (experience[playerSource] or {})[name] or 0
            end
            function api.SetXP(playerSource, name, value)
                value = tonumber(value)
                if not value or value < 0 or value == math.huge or value ~= value then
                    return false, 'invalid_xp'
                end
                experience[playerSource] = experience[playerSource] or {}
                experience[playerSource][name] = value
                return true
            end
            function api.AddXP(playerSource, name, value)
                value = tonumber(value)
                if not value or value < 0 then
                    return false, 'invalid_xp'
                end
                return api.SetXP(playerSource, name, api.GetXP(playerSource, name) + value)
            end
            api.AddXp = api.AddXP
            function api.RemoveXp(playerSource, name, value)
                value = tonumber(value)
                if not value or value < 0 then
                    return false, 'invalid_xp'
                end
                return api.SetXP(playerSource, name, math.max(0, api.GetXP(playerSource, name) - value))
            end
            function api.GetSkillLevel(playerSource, name)
                local coreObject = config[name] or create(name)
                local xp = api.GetXP(playerSource, name)
                local level = 1
                while level < coreObject.maxLevel and xp >= threshold(name, level + 1) do
                    level = level + 1
                end
                return level
            end
            function api.SetSkillLevel(playerSource, name, level)
                return api.SetXP(playerSource, name, threshold(name, level))
            end
            function api.GetScaledXP(name, level)
                local coreObject = config[name] or create(name)
                return math.floor(coreObject.base * coreObject.scale ^ (math.max(1, level) - 1))
            end
        end
        return api
    end)
end
if providerRegistry.Server then
    DT.Callback.Register('DTlib:provider:skillLevel', function(playerSource, resource, name)
        local api = DT.Ecosystem.Get('skills', resource)
        return api and api.GetSkillLevel(playerSource, name)
    end)
    DT.Callback.Register('DTlib:provider:skillXP', function(playerSource, name)
        local api = DT.Ecosystem.Get('skills', 'native')
        return api.GetXP(playerSource, name)
    end)
    AddEventHandler('playerDropped', function()
        experience[source] = nil
    end)
end
