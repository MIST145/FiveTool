local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local props = {
    'prop_storagetank_02b',
}

local refuelProp = 'prop_oil_wellhead_06'

local coords = vector3(1733.08, -1556.68, 112.66)
local heading = 252.0
local tankerCoords = vector3(1738.34, -1530.89, 112.65)
local refuelheading = 254.5
local cooldown = 0
local blip = nil
local stationsRefueled = 0
local maxStations = 0
local truck = 0
local trailer = 0
local nozzleInHand = false
local Rope1 = nil
local Rope2 = nil
local playerPed = PlayerPedId()
local targetCoord = vector3(1688.59, -1460.29, 111.65)
local distanceThreshold = 15.0
local RefuelingStation = false
local timestried = 0
local StoredTruck = nil
local StoredTrailer = nil
local src = source

local trailerModels = {
    '1956216962',
    '3564062519'
}

local myBoxZone = BoxZone:Create(vector3(1694.6, -1460.75, 112.92), 26.8, 15, {
    heading = 345,
    debugPoly = false
})

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local pedModel = Config.PedType
local pedCoords = vector4(1721.87, -1557.67, 111.65, 243.12)

CreateThread(function()
    while true do
        FreezeEntityPosition(pumpProp, true)
        Wait(0)
    end
end)

CreateThread(function()
    local pedHash = GetHashKey(pedModel)
    RequestModel(pedHash)

    while not HasModelLoaded(pedHash) do
        Wait(0)
    end

    local targetped = CreatePed(4, pedHash, pedCoords.x, pedCoords.y, pedCoords.z, pedCoords.w, false, true)
    SetEntityAsMissionEntity(targetped, true, true)
    SetBlockingOfNonTemporaryEvents(targetped, true)
    SetPedDiesWhenInjured(targetped, false)
    SetPedCanRagdollFromPlayerImpact(targetped, false)
    SetPedCanRagdoll(targetped, false)
    SetPedCanPlayAmbientAnims(targetped, true)
    SetPedCanPlayAmbientBaseAnims(targetped, true)
    SetPedCanPlayGestureAnims(targetped, true)
    SetPedCanPlayVisemeAnims(targetped, false, false)
    SetPedCanPlayInjuredAnims(targetped, false)
    FreezeEntityPosition(targetped, true)
    SetEntityInvincible(targetped, true)

    if Config.UseMenu == true then
        if Config.Menu == 'esx' and Config.Target == 'esx' then
            exports['esx_target']:AddTargetModel({pedHash}, {
                options = {
                    {
                        num = 1,
                        type = "client",
                        event = "md-opentruckermenu",
                        icon = "fas fa-sign-in-alt",
                        label = "Talk To Boss!",
                    },
                },
                distance = 2.0,
            })
        end
    else
        if Config.Target == 'esx' then
            exports['esx_target']:AddTargetModel({pedHash}, {
                options = {
                    {
                        num = 1,
                        type = "server",
                        event = "md-checkCash",
                        icon = "fas fa-sign-in-alt",
                        label = "Rent a Truck and Start Work",
                    },
                    {
                        num = 2,
                        type = "server",
                        event = "md-ownedtruck",
                        icon = "fas fa-sign-in-alt",
                        label = "Start Work With Your Own Truck",
                    },
                    {
                        num = 3,
                        type = "client",
                        event = "GetTruckerPay",
                        icon = "fas fa-money-bill-wave",
                        label = "Get Paycheck",
                    },
                    {
                        num = 4,
                        type = "client",
                        event = "RestartJob",
                        icon = "fas fa-ban",
                        label = "Restart Job",
                    },
                },
                distance = 2.0,
            })
        end
    end
end)

Citizen.CreateThread(function()
    for _, info in pairs(Config.Blip) do
        local startblip = AddBlipForCoord(info.x, info.y, info.z)
        SetBlipSprite(startblip, info.id)
        SetBlipDisplay(startblip, 4)
        SetBlipScale(startblip, 0.5)
        SetBlipColour(startblip, info.color)
        SetBlipAsShortRange(startblip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(info.title)
        EndTextCommandSetBlipName(startblip)
    end
end)

RegisterNetEvent("md-opentruckermenu")
AddEventHandler("md-opentruckermenu", function()
    exports['esx_menu']:openMenu({
        {
            header = "Gas Delivery Job",
            txt = "",
            isMenuHeader = true
        },
        {
            header = "Rent a Truck and Start Work",
            txt = "Rent a Truck and Start Work. Additional Rental fees will be taken from you.",
            icon = "fas fa-sign-in-alt",
            params = {
                event = "md-checkCash",
            }
        },
        {
            header = "Start Work With Your Own Truck",
            txt = "Start Work With Your Own Truck. only the Trailer Fees will be taken from you",
            icon = "fas fa-sign-in-alt",
            params = {
                event = "md-ownedtruck",
            }
        },
        {
            header = "Get Paycheck",
            txt = "Get Your Paycheck",
            icon = "fas fa-money-bill-wave",
            params = {
                event = "GetTruckerPay",
            }
        },
        {
            header = "Restart Job",
            txt = "Restart The Job",
            icon = "fas fa-ban",
            params = {
                event = "RestartJob",
            }
        },
    })
end)

RegisterNetEvent("spawnTruck")
AddEventHandler("spawnTruck", function()
    ESX.Game.SpawnVehicle(Config.TruckToSpawn, coords, heading, function(veh)
        RemoveBlip(blip)
        DeleteVehicle(StoredTruck)
        TruckNetID = NetworkGetNetworkIdFromEntity(veh)
        if Config.Debug == true then
            print("truck ID: "..TruckNetID)
        end
        SetVehicleNumberPlateText(veh, 'TRUCK' .. tostring(math.random(1000, 9999)))
        SetEntityHeading(veh, heading)

        exports[Config.FuelScript]:SetFuel(veh, 100.0)

        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
        if Config.VehicleKeys == 'esx_vehiclekeys' then
            TriggerEvent("vehiclekeys:client:SetOwner", ESX.Game.GetVehicleProperties(veh).plate)
            SetVehicleEngineOn(veh, true, true, false)
        else
            if Config.VehicleKeys == 'mk_vehiclekeys' then
                exports["mk_vehiclekeys"]:AddKey(veh)
            end
        end
        truck = 1
        StoredTruck = NetworkGetEntityFromNetworkId(TruckNetID)
    end)

    ESX.Game.SpawnVehicle(Config.TrailerToSpawn, tankerCoords, heading, function(veh1)
        DeleteVehicle(StoredTrailer)
        TrailerNetID = NetworkGetNetworkIdFromEntity(veh1)
        if Config.Debug == true then
            print("trailer ID: "..TrailerNetID)
        end
        SetVehicleNumberPlateText(veh1, 'TRUCKER')
        SetEntityHeading(veh1, heading)

        StoredTrailer = NetworkGetEntityFromNetworkId(TrailerNetID)
    end)
end)

RegisterNetEvent("spawnTruck2")
AddEventHandler("spawnTruck2", function()

    ESX.Game.SpawnVehicle(Config.TrailerToSpawn, tankerCoords, heading, function(veh2)
        DeleteVehicle(StoredTrailer)
        TrailerNetID = NetworkGetNetworkIdFromEntity(veh2)
        if Config.Debug == true then
            print("trailer ID: "..TrailerNetID)
        end
        SetVehicleNumberPlateText(veh2, 'TRUCKER')
        SetEntityHeading(veh2, heading)

        truck = 1
        StoredTrailer = NetworkGetEntityFromNetworkId(TrailerNetID)
    end)
end)

RegisterNetEvent('TrailerBlip', function()
    blip = AddBlipForCoord(1736.51, -1530.79, 112.66)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 1.0)
    SetBlipRoute(blip, true)
    SetBlipFlashes(blip, true)
    ESX.ShowNotification('Go get your tanker!')

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)

            if vehicle ~= 0 then
                local trailer = GetVehicleTrailerVehicle(vehicle)

                if trailer == 1 then
                    RemoveBlip(blip)
                    TriggerEvent('spawnFlashingBlip')
                    if Config.Debug == true then
                        print("trailer connected")
                    end
                    break
                end
            end
        end
    end)
end)

RegisterNetEvent('spawnFlashingBlip', function()
    blip = AddBlipForCoord(1686.17, -1457.77, 112.39)
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 5)
    SetBlipScale(blip, 1.0)
    SetBlipRoute(blip, true)
    SetBlipFlashes(blip, true)
    ESX.ShowNotification('Go fuel up your tanker!')
    local pumpProp = CreateObject('prop_storagetank_02b', 1688.59, -1460.29, 111.65, true, false, false)
    SetEntityHeading(pumpProp, refuelheading)
    FreezeEntityPosition(pumpProp, true)
end)

function GetPump(coordss)
    local prop = nil
    local propCoords
    for i = 1, #props, 1 do
        local currentPumpModel = props[i]
        prop = GetClosestObjectOfType(coordss.x, coordss.y, coordss.z, 3.0, currentPumpModel, true, true, true)
        propCoords = GetEntityCoords(prop)
        if Config.Debug == true then
            print("Gas Pump: ".. prop,  "Pump Coords: "..propCoords)
        end
        if prop ~= 0 then break end
    end
    return propCoords, prop
end

RegisterNetEvent('refuelTanker', function()
    if Config.Debug == true then
        print("blip: ", blip)
    end

    local vehicle = GetLastDrivenVehicle()
    local trailer = 0
    local hasTrailer, trailerHandle = GetVehicleTrailerVehicle(vehicle, trailer)
    if truck == 1 then
        if not hasTrailer then
            ESX.ShowNotification('You need to get your tanker!')
        else
            if cooldown == 0 then
                local playerPed = PlayerPedId()
                LoadAnimDict("anim@am_hold_up@male")
                TaskPlayAnim(playerPed, "anim@am_hold_up@male", "shoplift_high", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
                TriggerServerEvent("InteractSound_SV:PlayOnSource", "pickupnozzle", 0.4)
                Wait(300)
                StopAnimTask(playerPed, "anim@am_hold_up@male", "shoplift_high", 1.0)
                fuelnozzle1 = CreateObject('prop_cs_fuel_nozle', 1.0, 1.0, 1.0, true, true, false)
                local lefthand = GetPedBoneIndex(playerPed, 18905)
                AttachEntityToEntity(fuelnozzle1, playerPed, lefthand, 0.13, 0.04, 0.01, -42.0, -115.0, -63.42, 0, 1, 0, 1, 0, 1)
                local grabbednozzlecoords = GetEntityCoords(playerPed)
                local propCoords, prop = GetPump(grabbednozzlecoords)
                RopeLoadTextures()
                while not RopeAreTexturesLoaded() do
                    Wait(0)
                    RopeLoadTextures()
                end
                while not prop do
                    Wait(0)
                end
                Rope1 = AddRope(propCoords.x, propCoords.y, propCoords.z, 0.0, 0.0, 0.0, 3.0, 3, 10.0, 0.0, 1.0, false, false, false, 1.0, true)
                while not Rope1 do
                    Wait(0)
                end
                ActivatePhysics(Rope1)
                Wait(100)
                local nozzlePos1 = GetEntityCoords(fuelnozzle1)
                nozzlePos1 = GetOffsetFromEntityInWorldCoords(fuelnozzle1, 0.0, -0.033, -0.195)
                AttachEntitiesToRope(Rope1, prop, fuelnozzle1, propCoords.x, propCoords.y, propCoords.z + 2.1, nozzlePos1.x, nozzlePos1.y, nozzlePos1.z, length, false, false, nil, nil)
                nozzleInHand = true
                BringToTruck()
                Citizen.CreateThread(function()
                    while nozzleInHand do
                        local currentcoords = GetEntityCoords(playerPed)
                        local dist = #(grabbednozzlecoords - currentcoords)
                        if dist > 10.0 then
                            ESX.ShowNotification('Your fuel line has broken!')
                            nozzleInHand = false
                            FreezeEntityPosition(trailerId, false)
                            DeleteObject(fuelnozzle1)
                            RopeUnloadTextures()
                            DeleteRope(Rope1)
                        end
                        Wait(2500)
                    end
                end)
            else
                ESX.ShowNotification('You have already fueled your truck!')
            end
        end
    else
        ESX.ShowNotification('You do not have a truck!')
    end
end)

RegisterNetEvent('ReturnNozzle', function()
    nozzleInHand = false
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "putbacknozzle", 0.4)
    Wait(250)
    DeleteObject(fuelnozzle1)
    DeleteObject(fuelnozzle2)
    RopeUnloadTextures()
    DeleteRope(Rope1)
    DeleteRope(Rope2)
    ResetNozzleInHand()
end)

function ResetNozzleInHand()
    nozzleInHand = false
end

function BringToTruck()
    if Config.Debug == true then
        print("cooldown: " .. cooldown)
    end
    CreateThread(function()
        local insideZone = false
        while true do
            Wait(500)
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            if myBoxZone:isPointInside(playerCoords) then
                if not insideZone then
                    insideZone = true
                    if truck == 1 and cooldown == 0 then
                        ESX.ShowNotification('Go fuel up the tanker!')
                        if Config.Target == 'esx' then
                            for _, model in ipairs(trailerModels) do
                                local modelHash = tonumber(model)
                                exports['esx_target']:AddTargetModel({modelHash}, {
                                    options = {
                                        {
                                            type = "client",
                                            event = "FuelTruck",
                                            icon = "fas fa-gas-pump",
                                            label = "Fuel Truck",
                                            canInteract = function()
                                                if cooldown == 0 then
                                                    return true
                                                else
                                                    return false
                                                end
                                            end
                                        },
                                    },
                                    distance = 5.0,
                                })
                            end
                        end
                    end
                    if Config.Debug == true then
                        print("Player has entered the box zone")
                    end
                end
            else
                if insideZone then
                    insideZone = false
                    if Config.Debug == true then
                        print("Player has left the box zone")
                    end
                end
            end
        end
    end)
end

RegisterNetEvent('FuelTruck', function()
    local playerPed = PlayerPedId()
    LoadAnimDict("timetable@gardener@filling_can")
    TaskPlayAnim(playerPed, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 8.0, 1.0, -1, 1, 0, 0, 0, 0)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "refuel", 0.3)
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'refueling', {
        title = 'Refueling',
        align = 'top-left',
        elements = {
            {label = 'Refueling Tanker', value = 'refueling'}
        }
    }, function(data, menu)
        cooldown = cooldown + 1
        maxStations = 0
        StopAnimTask(playerPed, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "fuelstop", 0.4)
        ESX.ShowNotification('You have finished refueling. You will be receiving an email with the location soon!')
        RemoveBlip(blip)
        Wait(10000)
        GetNextLocation()
    end, function(data, menu)
        StopAnimTask(playerPed, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3.0, 3.0, -1, 2, 0, 0, 0, 0)
        TriggerServerEvent("InteractSound_S
