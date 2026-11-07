local providerRegistry = DT.Providers
if providerRegistry.Server then
    providerRegistry.Register('helptext', 'native', function()
        return {
            ShowHelpText = function(playerSource, text, position)
                TriggerClientEvent('DTlib:provider:textShow', playerSource, text, position)
                return true
            end,
            HideHelpText = function(playerSource)
                TriggerClientEvent('DTlib:provider:textHide', playerSource)
                return true
            end,
        }
    end)
    providerRegistry.Register('notify', 'native', function()
        local api = {}
        function api.SendNotification(playerSource, title, message, kind, duration, properties)
            local data = DTUtils.copy(properties or {})
            data.title = title
            data.message = message
            data.type = kind
            data.duration = duration
            return DT.Notify(playerSource, data)
        end
        function api.SendNotify(playerSource, message, kind, duration)
            return api.SendNotification(playerSource, nil, message, kind, duration)
        end
        function api.ShowHelpText(...)
            return DT.Ecosystem.HelpText.ShowHelpText(...)
        end
        function api.HideHelpText(...)
            return DT.Ecosystem.HelpText.HideHelpText(...)
        end
        return api
    end)
else
    RegisterNetEvent('DTlib:provider:textShow', function(text, position)
        if source == 65535 then
            DT.TextUI.Show(text, { position = position })
        end
    end)
    RegisterNetEvent('DTlib:provider:textHide', function()
        if source == 65535 then
            DT.TextUI.Hide()
        end
    end)
end
