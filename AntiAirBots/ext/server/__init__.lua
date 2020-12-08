require('Tables')
require('__shared/Config')
local Bots = require('bots')
local Target = require('Target')
local AntiAirBot = require('AntiAirBot')
local TargetToBot = require('TargetToBot')

local targetTable = {}
local antiAirBotTable = {}
local targetAssignments = {}
local vehicleNamesTable = createVehicleNamesTable()

local refreshRate = 0
local refreshTime = 1
local maxRange = Config.projectileSpeed * Config.projectileTimeToLive
local botHeightAdjustment = 1.6
local blueprint_f18 = nil

ResourceManager:RegisterInstanceLoadHandler(Guid('3EABB4EF-4003-11E0-8ACA-C41D37DB421C'), Guid('C81F8757-E6D2-DF2D-1CFE-B72B4F74FE98'), function(instance)
    blueprint_f18 = VehicleBlueprint(instance)
end)

function createTarget(vehicle, player)

    if player == nil or vehicle == nil then
        return
    end

    --return if player is already in the table
    for _, target in pairs(targetTable) do
        if target.player.id == player.id then
            return
        end   
    end
    
    --add to table
    local vehicleName = VehicleEntityData(vehicle.data).nameSid

    for _, name in pairs(vehicleNamesTable) do
        if vehicleName == name then
            local target = Target()
            target.player = player
            target.vehicle = vehicle
            table.insert(targetTable, target)
        break end   
    end
end

function removeTarget(player)

    if player == nil then
        return
    end

    for i = 1, #targetTable do
        if targetTable[i].player.id == player.id then 
            table.remove(targetTable, i)
            return
        end      
    end
end

function createAntiAirBot(team, position)

    if team == nil or position == nil then 
        return
    end

    --if a dead bot is available then spawn this bot
    for _, antiAirBot in pairs(antiAirBotTable) do
        if not antiAirBot.bot.alive and antiAirBot.bot.teamId == team then
            antiAirBot:spawnBot(position)
            return
        end
    end

    --create a new bot
    local bot = Bots:createBot('AntiAirBot' .. (#antiAirBotTable + 1), team, SquadId.SquadNone)
    local antiAirBot = AntiAirBot()
    antiAirBot.bot = bot
    antiAirBot:spawnBot(position)

    --local botHeightAdjustment = antiAirBot.bot.input.authoritativeCameraPosition.y
    antiAirBot.position = Vec3(position.x, position.y, position.z)
    table.insert(antiAirBotTable, antiAirBot)
end

function removeAntiAirBot(bot)

    if bot == nil then
        return
    end

    for i = 1, #antiAirBotTable do
        if antiAirBotTable[i].bot.id == bot.id then
            table.remove(antiAirBotTable, i)
            return
        end      
    end
end

function botHasTarget(botId)
    for _, assignment in pairs(targetAssignments) do
        if assignment.antiAirBotId == botId then
            return true
        end   
    end
    return false
end

function assignTargetsToBots()

    local targetsToBots = {}
    --targetAssignments = {}

     --get the distance of each bot to each enemy target that is in range
    for i, target in pairs(targetTable) do
        for j, antiAirBot in pairs(antiAirBotTable) do
            if target.player.teamId ~= antiAirBot.bot.teamId then       
                local targetToBot = TargetToBot()
                targetToBot.targetPlayerId = target.player.id
                targetToBot.antiAirBotId = antiAirBot.bot.id
                targetToBot.distance = target:getDistance(antiAirBot.position)

                if targetToBot.distance <= maxRange then
                    table.insert(targetsToBots, targetToBot)
                end        
            end
        end
    end

    --assign each target to it's closest bot that has no target assigned to it
    for i = 1, #targetTable do
        local smallestDistance = nil
        local tbIdx = 0

        for j = 1, #targetsToBots do
            if targetTable[i].player.id == targetsToBots[j].targetPlayerId and not botHasTarget(targetsToBots[j].antiAirBotId) then
                if smallestDistance == nil then
                    smallestDistance = targetsToBots[j].distance
                    tbIdx = j
                elseif targetsToBots[j].distance < smallestDistance then
                    smallestDistance = targetsToBots[j].distance
                    tbIdx = j
                end    
            end          
        end

        if targetsToBots[tbIdx] ~= nil then
            table.insert(targetAssignments, targetsToBots[tbIdx])
        end
    end

    --assign bots to their closest traget if they have none (happens only if there are more bots than targets)
    for i = 1, #antiAirBotTable do
        if not botHasTarget(antiAirBotTable[i].bot.id) then
            local smallestDistance = nil
            local tbIdx = 0

            for j = 1, #targetsToBots do
                if antiAirBotTable[i].bot.id == targetsToBots[j].antiAirBotId then
                    if smallestDistance == nil then
                        smallestDistance = targetsToBots[j].distance
                        tbIdx = j
                    elseif targetsToBots[j].distance < smallestDistance then
                        smallestDistance = targetsToBots[j].distance
                        tbIdx = j
                    end    
                end          
            end

            if targetsToBots[tbIdx] ~= nil then
                table.insert(targetAssignments, targetsToBots[tbIdx])
            end
        end
    end
end

NetEvents:Subscribe('AntiAirBots:Spawn', function(player, team, position)
    if position == nil then
        position = player.soldier.worldTransform.trans
    end
    createAntiAirBot(team, position)
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

Events:Subscribe('Server:RoundOver', function(roundTime, winningTeam)
    targetTable = {}
    antiAirBotTable = {}
    targetAssignments = {}
    Bots:destroyAllBots()
end)

Events:Subscribe('Vehicle:Enter', function(vehicle, player)  
    createTarget(vehicle, player)
end)

Events:Subscribe('Vehicle:Exit', function(vehicle, player)
    removeTarget(player)
end)

Events:Subscribe('Player:Killed', function(player, inflictor, position, weapon, isRoadKill, isHeadShot, wasVictimInReviveState, info)
    removeTarget(player)
end)

Events:Subscribe('Player:Destroyed', function(player)
    removeTarget(player)
    removeAntiAirBot(player)
end)

Events:Subscribe('Engine:Update', function(deltaTime, simulationDeltaTime)
    
    refreshTime = refreshTime + deltaTime

    if refreshTime >= refreshRate then
        targetAssignments = {}
        if #targetTable > 0 and #antiAirBotTable > 0 then
            assignTargetsToBots()
        end
        refreshTime = 0    
    end
end)

Events:Subscribe('Bot:Update', function(bot, deltaTime)

    --aim bots at their assignet target and fire
    for i = 1, #targetAssignments do
        if targetAssignments[i].antiAirBotId == bot.id then
            if bot.alive then
                local tIdx = 0
                local bIdx = 0

                for j = 1, #targetTable do
                    if targetTable[j].player.id == targetAssignments[i].targetPlayerId then
                        tIdx = j
                    break end
                end

                for j = 1, #antiAirBotTable do
                    if antiAirBotTable[j].bot.id == targetAssignments[i].antiAirBotId then
                        bIdx = j
                    break end
                end

                local trans = antiAirBotTable[bIdx].bot.soldier.worldTransform.trans    
                --local botHeightAdjustment = antiAirBotTable[i].bot.input.authoritativeCameraPosition.y
                antiAirBotTable[bIdx].position = Vec3(trans.x, trans.y + botHeightAdjustment, trans.z)

                if antiAirBotTable[bIdx] ~= nil and targetTable[tIdx] ~= nil then
                    local interceptPos = targetTable[tIdx]:getInterceptingPosition(antiAirBotTable[bIdx].position)

                    if interceptPos ~= nil then
                        antiAirBotTable[bIdx].aimPosition = interceptPos
                    else
                        antiAirBotTable[bIdx].aimPosition = targetTable[tIdx].player.soldier.worldTransform.trans
                    end

                    antiAirBotTable[bIdx]:aimYaw()
                    antiAirBotTable[bIdx]:aimPitch()
                end    
            end     
        break end
    end

    if botHasTarget(bot.id) then
        bot.input:SetLevel(EntryInputActionEnum.EIAFire, 1)
    else
        bot.input:SetLevel(EntryInputActionEnum.EIAFire, 0)
    end
  

    --kill test targets after the specified amount of time
    if bot.name == 'TargetBot' and bot.alive then                
        for i = 1, #targetTable do 
            if targetTable[i].player.id == bot.id then
                targetTable[i].timeAlive = targetTable[i].timeAlive + deltaTime

                if targetTable[i].timeAlive >= Config.targetBotTimeToLive then     
                    local soldier = targetTable[i].player.soldier
                    local vehicle = targetTable[i].vehicle
                    soldier:Kill()
                    vehicle:Destroy()                    
                end
            break end
        end
    end
end)






