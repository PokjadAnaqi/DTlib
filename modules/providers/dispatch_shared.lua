local providerRegistry = DT.Providers
local function normalized(data)
    assert(type(data) == 'table', 'invalid_alert')
    local result = DTUtils.copy(data)
    result.coords = result.coords or (not providerRegistry.Server and GetEntityCoords(PlayerPedId()))
    assert(result.coords, 'alert_coords_required')
    result.message = result.message or result.title or 'Dispatch alert'
    result.code = result.code or '10-80'
    result.priority = result.priority or 2
    result.jobs = result.jobs or result.job or { 'police' }
    if type(result.jobs) == 'string' then
        result.jobs = { result.jobs }
    end
    result.blipData = result.blipData or result.blip or {}
    result.time = tonumber(result.time) or 10000
    return result
end
local function blip(data)
    local mapBlip = data.blipData
    return {
        sprite = mapBlip.sprite or 161,
        color = mapBlip.color or 1,
        scale = mapBlip.scale or 1,
        radius = mapBlip.radius or 0,
        length = math.max(1, data.time / 60000),
    }
end
local function send(resource, data, playerSource)
    local details = normalized(data)
    local mapBlip = blip(details)
    if resource == 'native' then
        if not providerRegistry.Server then
            return DT.Callback.Await('DTlib:provider:dispatch', resource, details)
        end
        local sent = {}
        for _, name in ipairs(details.jobs) do
            for _, target in ipairs(DT.Ecosystem.Framework.GetPlayersByJob(name)) do
                if not sent[target] then
                    sent[target] = true
                    TriggerClientEvent('DTlib:provider:dispatchNotice', target, details)
                end
            end
        end
        return true
    end
    if resource == 'emergencydispatch' then
        return providerRegistry.Event(
            'emergencydispatch:emergencycall:new',
            details.jobs[1],
            details.message,
            details.coords,
            true
        )
    end
    if providerRegistry.Server then
        if resource == 'lb-tablet' then
            return providerRegistry.Export(resource, 'AddDispatch', {
                priority = ({ [1] = 'high', [2] = 'medium', [3] = 'low' })[details.priority] or 'medium',
                code = details.code,
                title = details.message,
                description = details.message,
                location = { label = details.street or 'Reported location', coords = details.coords },
                time = details.time / 1000,
                job = details.jobs[1],
            })
        end
        if resource == 'fd_dispatch' then
            return providerRegistry.Export(resource, 'addAlert', {
                title = details.message,
                description = details.message,
                groups = details.jobs,
                coords = details.coords,
                code = details.code,
                priority = details.priority,
                blip = mapBlip,
            })
        end
        if resource == 'redutzu-mdt' then
            return providerRegistry.Event(
                'redutzu-mdt:server:addDispatchToMDT',
                {
                    code = details.code,
                    title = details.message,
                    street = details.street,
                    duration = details.time,
                    coords = details.coords,
                }
            )
        end
        if resource == 'piotreq_gpt' then
            return providerRegistry.Export(resource, 'SendAlert', assert(playerSource, 'alert_source_required'), {
                title = details.message,
                code = details.code,
                icon = details.icon or 'fa-solid fa-bell',
                info = { { data = details.message, icon = 'fa-solid fa-circle-info' } },
                blip = {
                    name = details.message,
                    scale = mapBlip.scale,
                    sprite = mapBlip.sprite,
                    color = mapBlip.color,
                    priority = details.priority,
                },
                type = 'normal',
                time = details.time / 60000,
            })
        end
        return nil, 'client_only_method:SendAlert'
    end
    if resource == 'lb-tablet' or resource == 'redutzu-mdt' or resource == 'piotreq_gpt' then
        return DT.Callback.Await('DTlib:provider:dispatch', resource, details)
    end
    if resource == 'ps-dispatch' then
        return providerRegistry.Export(resource, 'CustomAlert', {
            message = details.message,
            code = details.code,
            icon = details.icon,
            priority = details.priority,
            coords = details.coords,
            vehicle = details.vehicle,
            plate = details.plate,
            alertTime = details.time / 1000,
            radius = mapBlip.radius,
            sprite = mapBlip.sprite,
            color = mapBlip.color,
            scale = mapBlip.scale,
            length = mapBlip.length,
            jobs = details.jobs,
            flash = details.blipData.flash,
        })
    end
    if resource == 'fd_dispatch' then
        return providerRegistry.Export(resource, 'CustomAlert', {
            title = details.message,
            description = details.message,
            coords = details.coords,
            groups = details.jobs,
            code = details.code,
            priority = details.priority,
            blip = mapBlip,
        })
    end
    if resource == 'tk_dispatch' then
        return providerRegistry.Export(resource, 'addCall', {
            title = details.message,
            code = details.code,
            priority = 'Priority ' .. details.priority,
            coords = details.coords,
            showLocation = true,
            playSound = true,
            blip = mapBlip,
            jobs = details.jobs,
        })
    end
    if resource == 'wasabi_mdt' then
        return providerRegistry.Export(resource, 'CreateDispatch', {
            type = details.code,
            title = details.code,
            description = details.message,
            location = { details.coords.x, details.coords.y, details.coords.z },
            coords = { details.coords.x, details.coords.y, details.coords.z },
        })
    end
    if resource == 'bub-mdt' then
        return providerRegistry.Export(resource, 'CustomAlert', {
            code = details.code,
            offense = details.message,
            coords = details.coords,
            info = { label = details.code, icon = details.icon or 'fas fa-bell' },
            blip = mapBlip.sprite,
            isEmergency = details.priority == 1,
            blipCoords = details.coords,
        })
    end
    if resource == 'kartik-mdt' then
        local jobs = {}
        for _, name in ipairs(details.jobs) do
            jobs[name] = true
        end
        return providerRegistry.Export(
            resource,
            'CustomAlert',
            {
                title = details.message,
                description = details.message,
                code = details.code,
                type = 'Alert',
                coords = details.coords,
                blip = mapBlip,
                jobs = jobs,
            }
        )
    end
    if resource == 'cd_dispatch' then
        local info = providerRegistry.Export(resource, 'GetPlayerInfo') or {}
        mapBlip.colour = mapBlip.color
        mapBlip.time = details.time / 60000
        return providerRegistry.Event('cd_dispatch:AddNotification', {
            job_table = details.jobs,
            coords = details.coords,
            title = details.code,
            message = details.message,
            flash = details.blipData.flash or 0,
            unique_id = info.unique_id or providerRegistry.Id('alert'),
            sound = 1,
            blip = mapBlip,
        })
    end
    if resource == 'origen_police' then
        return providerRegistry.Event(
            'SendAlert:police',
            {
                coords = details.coords,
                title = details.code,
                message = details.message,
                job = details.jobs,
                metadata = {},
            }
        )
    end
    if resource == 'linden_outlawalert' then
        return providerRegistry.Event('wf-alerts:svNotify', {
            dispatchData = {
                displayCode = details.code,
                description = details.message,
                isImportant = details.priority == 1,
                recipientList = details.jobs,
            },
            caller = details.caller or 'Anonymous',
            coords = details.coords,
        })
    end
    if resource == 'qs-dispatch' then
        mapBlip.colour = mapBlip.color
        return providerRegistry.Event('qs-dispatch:server:CreateDispatchCall', {
            job = details.jobs,
            callLocation = details.coords,
            callCode = { code = details.code, snippet = details.message },
            message = details.message,
            flashes = details.blipData.flash or false,
            blip = mapBlip,
        })
    end
    return nil, 'unsupported_method:SendAlert'
end
for _, definition in ipairs(DTEcosystemCatalog.dispatch.providers) do
    providerRegistry.Register('dispatch', definition.resource, function(resource)
        if
            providerRegistry.Server
            and not ({
                native = true,
                emergencydispatch = true,
                ['lb-tablet'] = true,
                fd_dispatch = true,
                ['redutzu-mdt'] = true,
                piotreq_gpt = true,
            })[resource]
        then
            return {}
        end
        return {
            SendAlert = function(data, second)
                if type(data) == 'number' then
                    return send(resource, second, data)
                end
                return send(resource, data, data.source)
            end,
        }
    end)
end
if providerRegistry.Server then
    local cooldown = {}
    DT.Callback.Register('DTlib:provider:dispatch', function(playerSource, resource, data)
        if type(data) ~= 'table' or type(data.message) ~= 'string' or #data.message > 1000 then
            return false, 'invalid_alert'
        end
        if cooldown[playerSource] and GetGameTimer() - cooldown[playerSource] < 3000 then
            return false, 'rate_limited'
        end
        cooldown[playerSource] = GetGameTimer()
        data = DTUtils.copy(data)
        data.coords = GetEntityCoords(GetPlayerPed(playerSource))
        local api = DT.Ecosystem.Get('dispatch', resource)
        if not api or not api.SendAlert then
            return false, 'unsupported_method'
        end
        return api.SendAlert(playerSource, data)
    end)
    AddEventHandler('playerDropped', function()
        cooldown[source] = nil
    end)
else
    RegisterNetEvent('DTlib:provider:dispatchNotice', function(data)
        if source ~= 65535 then
            return
        end
        DT.Notify({ title = data.code, message = data.message, duration = data.time })
        local mapBlip = blip(data)
        local mark = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
        SetBlipSprite(mark, mapBlip.sprite)
        SetBlipColour(mark, mapBlip.color)
        SetBlipScale(mark, mapBlip.scale)
        SetTimeout(math.max(1000, math.min(data.time, 300000)), function()
            RemoveBlip(mark)
        end)
    end)
end
