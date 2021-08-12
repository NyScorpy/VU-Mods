require('__shared/Config')
local Bots = require('bots')
local Target = require('Target')
local BotManager = require('BotManager')
local Target = Target()
local BotManager = BotManager()

Events:Subscribe('Level:Loaded', function(levelName, gameMode, round, roundsPerMap)
    BotManager:onLevelLoaded(levelName, gameMode)
end)

Events:Subscribe('Server:RoundReset', function()
    BotManager.antiAirBots = {}
    BotManager.targets = {}
    --destroy all bots to prevent server crash while loading a new level
    Bots:destroyAllBots()
    BotManager.levelLoaded = false
    BotManager.initailSpawnCompleted = false
    BotManager.spawnDelta = 0
end)

Events:Subscribe('Server:RoundOver', function(roundTime, winningTeam)
    BotManager.antiAirBots = {}
    BotManager.targets = {}
    --destroy all bots to prevent server crash while loading a new level
    Bots:destroyAllBots()
    BotManager.levelLoaded = false
    BotManager.initailSpawnCompleted = false
    BotManager.UsAAExists = false
    BotManager.RuAAExists = false
    BotManager.AAcheckCompleted = false
    BotManager.spawnDelta = 0
end)

Events:Subscribe('Vehicle:Enter', function(vehicle, player)  
    BotManager:createTarget(vehicle, player)
end)

Events:Subscribe('Vehicle:Exit', function(vehicle, player)
    if vehicle ~= nil then
        local vehicleName = VehicleEntityData(vehicle.data).controllableType

        if vehicleName ~= 'Vehicles/common/WeaponData/AGM-144_Hellfire_TV' then
            BotManager:removeTarget(player)
        end
    else
        BotManager:removeTarget(player)
    end
end)

Events:Subscribe('Player:Killed', function(player, inflictor, position, weapon, isRoadKill, isHeadShot, wasVictimInReviveState, info)
    BotManager:removeTarget(player)
end)

Events:Subscribe('Player:Destroyed', function(player)
    BotManager:removeTarget(player)
    BotManager:removeAntiAirBot(player)
end)

Events:Subscribe('Engine:Update', function(deltaTime, simulationDeltaTime)
    BotManager:onEngineUpdate(deltaTime)
end)

Events:Subscribe('Bot:Update', function(bot, deltaTime)
    BotManager:onBotUpdate(bot, deltaTime)
end)

if Config.debugMode then
    local blueprint_f18 = nil

    ResourceManager:RegisterInstanceLoadHandler(Guid('3EABB4EF-4003-11E0-8ACA-C41D37DB421C'), Guid('C81F8757-E6D2-DF2D-1CFE-B72B4F74FE98'), function(instance)
        blueprint_f18 = VehicleBlueprint(instance)
    end)

    NetEvents:Subscribe('Target:Spawn', function(player, count, team, position)
        local x = 0
        local z = 0

        for i = 1, count do
            Target:spawnTarget(blueprint_f18, team, position + Vec3(x, 0, z))

            if i % 2 == 1 then
                x = x * -1
                x = x + 35
                z = z - 35
            else
                x = x * -1
            end   
        end   
    end)

    Events:Subscribe('Bot:Update', function(bot, deltaTime)
        BotManager:onBotUpdate_debug(bot, deltaTime)
    end) 
end