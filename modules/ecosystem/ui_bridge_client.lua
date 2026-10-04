local active={}
local actions={
    progress=function(data) return DT.Progress(data) end,
    input=function(data) return DT.Input.Await(data) end,
    alert=function(data) return DT.Alert.Await(data) end
}
AddEventHandler('DTlib:ui:bridge:request',function(token,action,data)
    if type(token)~='string' or type(action)~='string' or not actions[action] then return end
    if active[action] then TriggerEvent('DTlib:ui:bridge:response',token,{nil,'busy'});return end
    active[action]=token
    CreateThread(function()
        local values=table.pack(pcall(actions[action],data))
        active[action]=nil
        local result
        if values[1] then
            result={n=values.n-1};for i=2,values.n do result[i-1]=values[i] end
        else result={n=2,[2]=tostring(values[2])} end
        TriggerEvent('DTlib:ui:bridge:response',token,result)
    end)
end)
AddEventHandler('onClientResourceStop',function(name)
    for action,token in pairs(active) do
        if token:sub(1,#name+1)==name..':' then
            if action=='progress' then DT.ProgressCancel()
            elseif action=='input' then DT.Input.Close()
            elseif action=='alert' then DT.Alert.Close() end
        end
    end
end)
