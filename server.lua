ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('md-checkCash')
AddEventHandler('md-checkCash', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local moneyType = Config.PayType
    local balance = xPlayer.getAccount(moneyType).money
    if Config.Debug == true then
        print(moneyType)
    end
    if balance >= Config.TruckPrice then
        xPlayer.removeAccountMoney(moneyType, Config.TruckPrice)
        TriggerClientEvent('spawnTruck', src)
        TriggerClientEvent('TrailerBlip', src)
    else
        TriggerClientEvent('NotEnoughTruckMoney', src)
    end
end)

RegisterServerEvent('md-ownedtruck')
AddEventHandler('md-ownedtruck', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local moneyType = Config.PayType
    local balance = xPlayer.getAccount(moneyType).money
    if Config.Debug == true then
        print(moneyType)
    end
    if balance >= Config.TankPrice then
        xPlayer.removeAccountMoney(moneyType, Config.TankPrice)
        TriggerClientEvent('spawnTruck2', src)
        TriggerClientEvent('TrailerBlip', src)
    else
        TriggerClientEvent('NotEnoughTankMoney', src)
    end 
end)

RegisterServerEvent('md-getpaid')
AddEventHandler('md-getpaid', function(stationsRefueled)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local moneyType = Config.PayType
    xPlayer.addAccountMoney(moneyType, stationsRefueled * Config.PayPerFueling)
end)
