Dispatch = Dispatch or {}

RegisterNetEvent("DTlib:ecosystem:Server:DispatchAlert", function(data)
    local jobs = data.jobs
    for _, name in pairs(jobs) do
        local activeJobPlayers = Bridge.Framework.GetPlayersByJob(name)
        for _, src in pairs(activeJobPlayers) do
            TriggerClientEvent('DTlib:ecosystem:Client:DispatchAlert', src, data)
        end
    end
end)

---This will get the name of the in use resource.
---@return string
Dispatch.GetResourceName = function()
    return 'default'
end

return Dispatch
