local P=DT.Providers
if P.Server then
    P.Register('helptext','native',function()
        return {ShowHelpText=function(src,text,position) TriggerClientEvent('DTlib:provider:textShow',src,text,position);return true end,
            HideHelpText=function(src) TriggerClientEvent('DTlib:provider:textHide',src);return true end}
    end)
    P.Register('notify','native',function()
        local api={}
        function api.SendNotification(src,title,message,kind,duration,properties)
            local data=DTUtils.copy(properties or {});data.title=title;data.message=message;data.type=kind;data.duration=duration
            return DT.Notify(src,data)
        end
        function api.SendNotify(src,message,kind,duration) return api.SendNotification(src,nil,message,kind,duration) end
        function api.ShowHelpText(...) return DT.Ecosystem.HelpText.ShowHelpText(...) end
        function api.HideHelpText(...) return DT.Ecosystem.HelpText.HideHelpText(...) end
        return api
    end)
else
    RegisterNetEvent('DTlib:provider:textShow',function(text,position) if source==65535 then DT.TextUI.Show(text,{position=position}) end end)
    RegisterNetEvent('DTlib:provider:textHide',function() if source==65535 then DT.TextUI.Hide() end end)
end
