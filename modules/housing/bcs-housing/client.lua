if GetResourceState('bcs-housing') == 'missing' then return end

Housing = Housing or {}

RegisterNetEvent('Housing:client:EnterHome', function(insideId)
    TriggerServerEvent('DTlib:ecosystem:Server:_OnPlayerInside', insideId)
end)

RegisterNetEvent("Housing:client:DeleteFurnitures", function()
    TriggerServerEvent('DTlib:ecosystem:Server:_OnPlayerInside', false)
end)

---This will get the name of the in use resource.
---@return string
Housing.GetResourceName = function()
    return "bcs-housing"
end

return Housing