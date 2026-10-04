function DT.Vehicle.GetPlate(vehicle)
    if not vehicle or vehicle == 0 then return nil end
    return DTUtils.trim(GetVehicleNumberPlateText(vehicle))
end

function DT.Vehicle.GetClosest(coords, radius)
    coords = coords or GetEntityCoords(PlayerPedId())
    radius = radius or 5.0
    local vehicles = GetGamePool('CVehicle')
    local closest, distance
    for i = 1, #vehicles do
        local dist = #(coords - GetEntityCoords(vehicles[i]))
        if dist <= radius and (not distance or dist < distance) then
            closest, distance = vehicles[i], dist
        end
    end
    return closest, distance
end

function DT.Vehicle.GetProperties(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    local color1, color2 = GetVehicleColours(vehicle)
    local pearl, wheel = GetVehicleExtraColours(vehicle)
    return {
        model = GetEntityModel(vehicle),
        plate = DT.Vehicle.GetPlate(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        engineHealth = GetVehicleEngineHealth(vehicle),
        tankHealth = GetVehiclePetrolTankHealth(vehicle),
        fuelLevel = GetVehicleFuelLevel(vehicle),
        dirtLevel = GetVehicleDirtLevel(vehicle),
        color1 = color1,
        color2 = color2,
        pearlescentColor = pearl,
        wheelColor = wheel
    }
end

function DT.Vehicle.SetProperties(vehicle, props)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or type(props) ~= 'table' then return false end
    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
    if props.color1 or props.color2 then
        local c1, c2 = GetVehicleColours(vehicle)
        SetVehicleColours(vehicle, props.color1 or c1, props.color2 or c2)
    end
    return true
end
