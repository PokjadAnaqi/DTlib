local providerRegistry = DT.Providers
for _, definition in ipairs(DTEcosystemCatalog.framework.providers) do
    providerRegistry.Register('framework', definition.resource, function(resource)
        local adapter = DT.Modules.Get('framework', resource == 'native' and 'standalone' or resource)
        assert(adapter, 'framework_adapter_missing')
        local api = {
            GetFrameworkName = function()
                return resource
            end,
        }
        local function call(method, ...)
            if type(adapter[method]) ~= 'function' then
                return nil, 'unsupported_method:' .. method
            end
            return adapter[method](adapter, ...)
        end
        function api.GetPlayerData(playerSource)
            return call('getData', playerSource) or {}
        end
        function api.GetPlayerIdentifier(playerSource)
            return providerRegistry.Server and call('getIdentifier', playerSource)
                or (api.GetPlayerData().citizenid or api.GetPlayerData().identifier)
        end
        function api.GetPlayerName(playerSource)
            local data = api.GetPlayerData(playerSource)
            local identity = data.charinfo or data
            return identity.firstname or identity.firstName or call('getName', playerSource),
                identity.lastname or identity.lastName or ''
        end
        function api.GetPlayerDob(playerSource)
            local details = api.GetPlayerData(playerSource)
            return (details.charinfo or details).birthdate or details.dateofbirth
        end
        function api.GetPlayerPhone(playerSource)
            local details = api.GetPlayerData(playerSource)
            return (details.charinfo or details).phone
        end
        local function job(playerSource)
            return call(providerRegistry.Server and 'getJobFor' or 'getJob', playerSource) or {}
        end
        function api.GetPlayerJob(playerSource)
            local jobData = job(playerSource)
            local grade = type(jobData.grade) == 'table' and jobData.grade
                or { level = jobData.grade, name = jobData.gradeName or jobData.grade_name }
            return jobData.name, jobData.label, grade.name, grade.level or grade.grade or 0
        end
        function api.GetPlayerJobData(playerSource)
            local jobData = job(playerSource)
            local grade = type(jobData.grade) == 'table' and jobData.grade
                or { level = jobData.grade, name = jobData.gradeName or jobData.grade_name, label = jobData.gradeLabel }
            return {
                jobName = jobData.name,
                jobLabel = jobData.label,
                gradeName = grade.name,
                gradeLabel = grade.label or grade.name,
                gradeRank = grade.level or 0,
                boss = jobData.isboss or jobData.boss or false,
                onDuty = jobData.onduty or jobData.onDuty or false,
            }
        end
        function api.GetPlayerGang(playerSource)
            local providerResult = call(providerRegistry.Server and 'getGangFor' or 'getGang', playerSource) or {}
            local groups = type(providerResult.grade) == 'table' and providerResult.grade
                or { level = providerResult.grade }
            return providerResult.name, providerResult.label, groups.name, groups.level
        end
        function api.GetPlayerDuty(playerSource)
            local jobData = job(playerSource)
            return jobData.onduty == true or jobData.onDuty == true
        end
        function api.GetPlayerMetadata(playerSource, key)
            if not providerRegistry.Server then
                key = playerSource
                playerSource = nil
            end
            return call('getMeta', playerSource, key)
        end
        if not providerRegistry.Server then
            api.GetPlayerMetadata = function(key)
                return call('getMeta', key)
            end
        end
        api.GetPlayerMetaData = api.GetPlayerMetadata
        function api.GetIsPlayerDead(playerSource)
            local details = api.GetPlayerData(playerSource)
            local methodName = details.metadata or {}
            return methodName.isdead == true or methodName.inlaststand == true or details.dead == true
        end
        function api.GetIsPlayerLoaded(playerSource)
            local details = api.GetPlayerData(playerSource)
            return details.citizenid ~= nil or details.identifier ~= nil
        end
        function api.GetIsFrameworkAdmin(playerSource)
            if providerRegistry.Server then
                return call('hasPermission', playerSource, 'admin') == true
            end
            return call('hasPermission', 'admin') == true
        end
        function api.GetPlayerInventory(playerSource)
            local details = api.GetPlayerData(playerSource)
            return details.items or details.inventory or {}
        end
        function api.GetStatus(playerSource, key)
            if not providerRegistry.Server then
                key = playerSource
                return call('getMeta', key)
            end
            return call('getMeta', playerSource, key)
        end
        function api.GetStatusData(playerSource)
            return api.GetPlayerData(playerSource).metadata or {}
        end
        for _, status in ipairs({ 'Hunger', 'Thirst', 'Stress' }) do
            local key = status:lower()
            api['Get' .. status] = function(playerSource)
                return providerRegistry.Server and call('getMeta', playerSource, key) or call('getMeta', key)
            end
            if providerRegistry.Server then
                api['Add' .. status] = function(playerSource, value)
                    return call(
                        'setMeta',
                        playerSource,
                        key,
                        math.max(
                            0,
                            math.min(100, (tonumber(call('getMeta', playerSource, key)) or 0) + (tonumber(value) or 0))
                        )
                    )
                end
                api['Remove' .. status] = function(playerSource, value)
                    return call(
                        'setMeta',
                        playerSource,
                        key,
                        math.max(
                            0,
                            math.min(100, (tonumber(call('getMeta', playerSource, key)) or 0) - (tonumber(value) or 0))
                        )
                    )
                end
            end
        end
        if not providerRegistry.Server then
            api.Notify = function(message, kind, duration)
                return DT.Notify({ message = message, type = kind, duration = duration })
            end
            api.ShowHelpText = function(text)
                return DT.TextUI.Show({ text = text })
            end
            api.HideHelpText = function()
                return DT.TextUI.Hide()
            end
            api.GetVehicleProperties = DT.Vehicle and DT.Vehicle.GetProperties
            api.SetVehicleProperties = DT.Vehicle and DT.Vehicle.SetProperties
            return api
        end
        local methods = {
            GetPlayer = 'getPlayer',
            GetPlayers = 'getPlayers',
            GetPlayerByIdentifier = 'getByIdentifier',
            GetFrameworkJobs = 'getJobs',
            SetPlayerJob = 'setJob',
            SetPlayerDuty = 'setJobDuty',
            GetAccountBalance = 'getMoney',
            AddAccountBalance = 'addMoney',
            RemoveAccountBalance = 'removeMoney',
            SetPlayerMetadata = 'setMeta',
        }
        for public, private in pairs(methods) do
            local name = private
            api[public] = function(...)
                return call(name, ...)
            end
        end
        function api.GetPlayerByIdentifier(id)
            return call(adapter.getByIdentifier and 'getByIdentifier' or 'getByCitizenId', id)
        end
        function api.ItemList(item)
            return DT.Ecosystem.Call('inventory', 'Items', item)
        end
        api.SetMetadata = function(...)
            return DT.Ecosystem.Call('inventory', 'SetMetadata', ...)
        end
        function api.GetPlayerSource(identifier)
            local player = api.GetPlayerByIdentifier(identifier)
            return player and (player.source or player.PlayerData and player.PlayerData.source)
        end
        function api.GetPlayersByJob(name, duty)
            local out = {}
            for _, playerSource in ipairs(DT.Player.GetPlayers()) do
                local jobData = job(playerSource)
                if jobData.name == name and (duty == nil or api.GetPlayerDuty(playerSource) == duty) then
                    out[#out + 1] = playerSource
                end
            end
            return out
        end
        api.GetPlayerSourcesByJob = api.GetPlayersByJob
        function api.GetJobCount(name, duty)
            return #api.GetPlayersByJob(name, duty)
        end
        function api.GetJobCountTotal()
            local result = {}
            for _, playerSource in ipairs(DT.Player.GetPlayers()) do
                local name = job(playerSource).name
                if name then
                    result[name] = (result[name] or 0) + 1
                end
            end
            return result
        end
        function api.SearchJobCountBySource(playerSource)
            return job(playerSource).name
        end
        -- Counts derive from framework state, so disconnects cannot leave stale manual counters.
        api.AddJobCount = function()
            return api.GetJobCountTotal()
        end
        api.RemoveJobCount = api.AddJobCount
        function api.RegisterUsableItem(name, callback)
            if resource == 'es_extended' then
                return providerRegistry.Export(resource, 'getSharedObject').RegisterUsableItem(name, callback)
            end
            if resource == 'qb-core' then
                return providerRegistry.Export(resource, 'GetCoreObject').Functions.CreateUseableItem(name, callback)
            end
            if resource == 'qbx_core' then
                return providerRegistry.Export(resource, 'CreateUseableItem', name, callback)
            end
            return nil, 'unsupported_method:RegisterUsableItem'
        end
        function api.RevivePlayer(playerSource)
            TriggerClientEvent(
                resource == 'es_extended' and 'esx_ambulancejob:revive' or 'hospital:client:Revive',
                playerSource
            )
            return true
        end
        for _, method in ipairs({ 'AddItem', 'RemoveItem', 'GetItemCount', 'GetItemInfo', 'GetItemBySlot', 'HasItem' }) do
            local name = method
            api[name] = function(...)
                return DT.Ecosystem.Call('inventory', name, ...)
            end
        end
        api.GetItem = api.GetItemInfo
        function api.GetOwnedVehicles(playerSource)
            local id = api.GetPlayerIdentifier(playerSource)
            if not id then
                return {}
            end
            return DT.Database.Query(
                resource == 'es_extended' and 'SELECT * FROM owned_vehicles WHERE owner = ?'
                    or 'SELECT * FROM player_vehicles WHERE citizenid = ?',
                { id }
            )
        end
        function api.IsVehicleOwnedByPlayer(playerSource, plate)
            for _, entry in ipairs(api.GetOwnedVehicles(playerSource) or {}) do
                if DTUtils.trim(entry.plate) == DTUtils.trim(plate) then
                    return true
                end
            end
            return false
        end
        return api
    end)
end
