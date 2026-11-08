local providerRegistry = DT.Providers
local ecosystem = DT.Ecosystem
for _, definition in ipairs(DTEcosystemCatalog.phone.providers) do
    providerRegistry.Register('phone', definition.resource, function(resource)
        local api = {
            GetPhoneName = function()
                return resource
            end,
        }
        if providerRegistry.Server then
            function api.GetPlayerPhone(playerSource)
                local method = {
                    ['lb-phone'] = 'GetEquippedPhoneNumber',
                    okokPhone = 'getPhoneNumberFromSource',
                    gksphone = 'GetPhoneBySource',
                    yseries = 'GetPhoneNumberBySourceId',
                }
                if method[resource] then
                    return providerRegistry.Export(resource, method[resource], playerSource)
                end
                if resource == 'qs-smartphone' then
                    return providerRegistry.Export('qs-base', 'GetPlayerPhone', playerSource)
                end
                local data = DT.Player.GetData(playerSource)
                return (data.charinfo or data).phone
            end
            function api.SendEmail(playerSource, sender, title, message)
                if resource == 'lb-phone' then
                    local number = api.GetPlayerPhone(playerSource)
                    if not number then
                        return false, 'phone_not_found'
                    end
                    local address = providerRegistry.Export(resource, 'GetEmailAddress', number)
                    if not address then
                        return false, 'email_not_found'
                    end
                    return providerRegistry.Export(
                        resource,
                        'SendMail',
                        { to = address, sender = sender, subject = title, message = message }
                    )
                end
                if resource == 'okokPhone' then
                    local address = providerRegistry.Export(resource, 'getEmailAddressFromSource', playerSource)
                    if not address then
                        return false, 'email_not_found'
                    end
                    return providerRegistry.Export(
                        resource,
                        'sendEmail',
                        { sender = sender, recipients = { address }, subject = title, body = message }
                    )
                end
                if resource == 'gksphone' then
                    return providerRegistry.Export(
                        resource,
                        'SendNewMail',
                        playerSource,
                        {
                            sender = sender,
                            subject = title,
                            message = message,
                            image = '/html/static/img/icons/mail.png',
                        }
                    )
                end
                if resource == 'qb-phone' then
                    return providerRegistry.Export(
                        resource,
                        'sendNewMailToOffline',
                        DT.Player.GetIdentifier(playerSource),
                        { sender = sender, subject = title, message = message, button = {} }
                    )
                end
                if resource == 'yseries' then
                    return providerRegistry.Export(
                        resource,
                        'SendMail',
                        { title = title, sender = sender, senderDisplayName = sender, content = message },
                        'phoneNumber',
                        api.GetPlayerPhone(playerSource)
                    )
                end
                if resource == 'qs-smartphone' then
                    TriggerClientEvent('DTlib:provider:phoneMail', playerSource, resource, sender, title, message)
                    return true
                end
                return nil, 'unsupported_method:SendEmail'
            end
        else
            function api.GetPlayerPhone()
                return DT.Callback.Await('DTlib:provider:phoneNumber', resource)
            end
            function api.SendEmail(sender, title, message)
                return DT.Callback.Await('DTlib:provider:phoneMail', resource, sender, title, message)
            end
        end
        return api
    end)
end
if providerRegistry.Server then
    local mailTimes = {}
    DT.Callback.Register('DTlib:provider:phoneNumber', function(playerSource, resource)
        local api = ecosystem.Get('phone', resource)
        return api and api.GetPlayerPhone(playerSource)
    end)
    DT.Callback.Register('DTlib:provider:phoneMail', function(playerSource, resource, sender, title, message)
        if
            type(sender) ~= 'string'
            or #sender > 254
            or type(title) ~= 'string'
            or #title > 200
            or type(message) ~= 'string'
            or #message > 8000
        then
            return false, 'invalid_mail'
        end
        local now = GetGameTimer()
        if mailTimes[playerSource] and now - mailTimes[playerSource] < 5000 then
            return false, 'rate_limited'
        end
        mailTimes[playerSource] = now
        local api = ecosystem.Get('phone', resource)
        return api and api.SendEmail(playerSource, sender, title, message)
    end)
    AddEventHandler('playerDropped', function()
        mailTimes[source] = nil
    end)
else
    RegisterNetEvent('DTlib:provider:phoneMail', function(resource, sender, title, message)
        if source ~= 65535 or resource ~= 'qs-smartphone' then
            return
        end
        TriggerServerEvent('qs-smartphone:server:sendNewMail', { sender = sender, subject = title, message = message })
    end)
end
for _, definition in ipairs(DTEcosystemCatalog.doorlock.providers) do
    providerRegistry.Register('doorlock', definition.resource, function(resource)
        local api = {}
        if providerRegistry.Server then
            local method =
                { doors_creator = 'setDoorState', ox_doorlock = 'setDoorState', rcore_doorlock = 'changeDoorState' }
            if method[resource] then
                api.ToggleDoorLock = function(id, locked)
                    return providerRegistry.Export(
                        resource,
                        method[resource],
                        tonumber(id) or id,
                        resource == 'rcore_doorlock' and (locked and 0 or 1) or (locked and 1 or 0)
                    )
                end
            end
            if resource == 'qb-doorlock' then
                api.ToggleDoorLock = function(id, locked)
                    TriggerClientEvent('qb-doorlock:client:setState', -1, 0, id, locked == true, false, false, false)
                    return true
                end
            end
        else
            local method = {
                doors_creator = 'getClosestActiveDoor',
                ox_doorlock = 'getClosestDoor',
                ['qb-doorlock'] = 'GetClosestDoor',
            }
            if method[resource] then
                api.GetClosestDoor = function()
                    local door = providerRegistry.Export(resource, method[resource])
                    return type(door) == 'table' and door.id or door
                end
            end
            if resource == 'rcore_doorlock' then
                api.GetClosestDoor = function()
                    local best, range = nil, math.huge
                    local pos = GetEntityCoords(PlayerPedId())
                    for _, door in pairs(providerRegistry.Export(resource, 'getLoadedDoors') or {}) do
                        local distance = #(pos - door.coords)
                        if distance < range then
                            best, range = door.id, distance
                        end
                    end
                    return best
                end
            end
        end
        return api
    end)
end
for _, definition in ipairs(DTEcosystemCatalog.bossmenu.providers) do
    providerRegistry.Register('bossmenu', definition.resource, function(resource)
        return {
            OpenBossMenu = function(playerSource, job, kind)
                if providerRegistry.Server then
                    local actual = DT.Player.GetJob(playerSource)
                    if not actual or actual.name ~= job or not (actual.isboss or actual.boss) then
                        return false, 'not_job_boss'
                    end
                    TriggerClientEvent('DTlib:provider:bossOpen', playerSource, resource, job, kind)
                    return true
                end
                job, kind = playerSource, job
                if resource == 'qb-management' then
                    TriggerEvent('qb-bossmenu:client:OpenMenu')
                    return true
                end
                if resource == 'esx_society' then
                    TriggerEvent('esx_society:openBossMenu', job, function(menu)
                        if menu and menu.close then
                            menu.close()
                        end
                    end, { wash = false })
                    return true
                end
                if resource == 'qbx_management' then
                    return providerRegistry.Export(resource, 'OpenBossMenu', kind or 'job')
                end
                if resource == 'tk_bosstablet' then
                    return providerRegistry.Export(resource, 'openBossMenu')
                end
                if resource == 'zat-bossmenu' then
                    return providerRegistry.Export(resource, 'OpenBossMenu', kind or 'job')
                end
                return nil, 'unsupported_method:OpenBossMenu'
            end,
        }
    end)
end
if not providerRegistry.Server then
    RegisterNetEvent('DTlib:provider:bossOpen', function(resource, job, kind)
        if source ~= 65535 then
            return
        end
        local api = ecosystem.Get('bossmenu', resource)
        if api then
            api.OpenBossMenu(job, kind)
        end
    end)
end
for _, definition in ipairs(DTEcosystemCatalog.housing.providers) do
    providerRegistry.Register('housing', definition.resource, function()
        return {
            GetInterior = function(playerSource)
                return providerRegistry.Server and Player(playerSource).state.dtlibInterior
                    or LocalPlayer.state.dtlibInterior
            end,
        }
    end)
end
if not providerRegistry.Server then
    AddEventHandler('Housing:client:EnterHome', function(id)
        LocalPlayer.state:set('dtlibInterior', id, true)
    end)
    AddEventHandler('Housing:client:DeleteFurnitures', function()
        LocalPlayer.state:set('dtlibInterior', false, true)
    end)
end
