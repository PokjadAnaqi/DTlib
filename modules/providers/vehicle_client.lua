local P=DT.Providers
local function plate(vehicle,value) return value or GetVehicleNumberPlateText(vehicle) end
local function model(vehicle) return GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)) end
for _,definition in ipairs(DTEcosystemCatalog.fuel.providers) do
    P.Register('fuel',definition.resource,function(resource)
        local native=resource=='native' or resource=='ox_fuel'
        return {
            GetFuel=function(vehicle)
                if native then return GetVehicleFuelLevel(vehicle) end
                return P.Export(resource,(resource=='ti_fuel' or resource=='x-fuel') and 'getFuel' or 'GetFuel',vehicle)
            end,
            SetFuel=function(vehicle,value,fuelType)
                value=tonumber(value);assert(value and value==value and value~=math.huge,'invalid_fuel')
                value=math.max(0,math.min(100,value))
                if native then
                    SetVehicleFuelLevel(vehicle,value)
                    if resource=='ox_fuel' then Entity(vehicle).state:set('fuel',value,true) end
                    return true
                end
                if resource=='ti_fuel' then return P.Export(resource,'setFuel',vehicle,value,fuelType or 'RON91') end
                return P.Export(resource,'SetFuel',vehicle,value)
            end
        }
    end)
end
local keyExports={
    mk_vehiclekeys={'AddKey','RemoveKey','vehicle'},MrNewbVehicleKeys={'GiveKeysByPlate','RemoveKeysByPlate'},
    ['Renewed-Vehiclekeys']={'addKey','removeKey'},wasabi_carlock={'GiveKey','RemoveKey'},
    mVehicle={'AddTemporalVehicleClient',nil,'vehicle'},t1ger_keys={'GiveTemporaryKeys',nil,'model'},
    ['qs-vehiclekeys']={'GiveKeys','RemoveKeys','model'}
}
local keyEvents={
    okokGarage={'okokGarage:GiveKeys','okokGarage:RemoveKeys'},
    ['qb-vehiclekeys']={'qb-vehiclekeys:server:AcquireVehicleKeys','qb-vehiclekeys:client:RemoveKeys'},
    qbx_vehiclekeys={'qb-vehiclekeys:server:AcquireVehicleKeys','qb-vehiclekeys:client:RemoveKeys'},
    F_RealCarKeysSystem={'F_RealCarKeysSystem:generateVehicleKeys','F_RealCarKeysSystem:removeVehicleKeysByPlate'},
    jaksams_VehiclesKeys={'vehicles_keys:selfGiveVehicleKeys','vehicles_keys:selfRemoveKeys'},
    cd_garage={'cd_garage:AddKeys'}
}
for _,definition in ipairs(DTEcosystemCatalog.vehiclekey.providers) do
    P.Register('vehiclekey',definition.resource,function(resource)
        local api={}
        local spec=keyExports[resource] or keyEvents[resource]
        for i,method in ipairs({'GiveKeys','RemoveKeys'}) do
            if spec and spec[i] then
                local index=i
                api[method]=function(vehicle,value)
                    value=plate(vehicle,value)
                    if keyExports[resource] then
                        if spec[3]=='vehicle' then return P.Export(resource,spec[index],vehicle) end
                        if spec[3]=='model' then return P.Export(resource,spec[index],value,model(vehicle),resource=='qs-vehiclekeys' and true or '') end
                        return P.Export(resource,spec[index],value)
                    end
                    if resource=='cd_garage' or ((resource=='qb-vehiclekeys' or resource=='qbx_vehiclekeys') and index==2) then TriggerEvent(spec[index],value)
                    else TriggerServerEvent(spec[index],value,GetPlayerServerId(PlayerId())) end
                    return true
                end
            end
        end
        return api
    end)
end
