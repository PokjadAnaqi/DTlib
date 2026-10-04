Housing = Housing or {}

---This is an internal event, listen for 'DTlib:ecosystem:Client:OnPlayerInside' instead.
---This event is triggered when a player enters or leaves a property.
---@param src number
---@param insideId string
RegisterNetEvent('DTlib:ecosystem:Server:_OnPlayerInside', function(src, insideId)
    local currentBucket = GetPlayerRoutingBucket(src)
    local playerEntity = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(playerEntity)
    TriggerEvent('DTlib:ecosystem:Client:OnPlayerInside', src, insideId, currentBucket, playerCoords)
end)

---This will get the name of the in use resource.
---@return string
Housing.GetResourceName = function()
    return "default"
end

return Housing