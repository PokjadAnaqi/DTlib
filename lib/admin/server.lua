RegisterNetEvent('DTlib:server:adminOpen',function()
    local source=source
    if not DT.Security.RateLimit(source,'admin_hub_open',4,10000) then return end
    if not DT.Security.RequireAdmin(source) then return end
    TriggerClientEvent('DTlib:client:adminOpen',source)
end)
