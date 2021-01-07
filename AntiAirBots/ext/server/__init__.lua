require('Tables')
require('__shared/Config')
local Bots = require('bots')
local Target = require('Target')
local AntiAirBot = require('AntiAirBot')
local TargetToBot = require('TargetToBot')
local TeamCount = require('TeamCount')

local targetTable = {}
local antiAirBotTable = {}
local vehicleNamesTable = createVehicleNamesTable()

local aRefreshRate = 1
local aRefreshTime = 0
local bRefreshRate = 60 / Config.fireRate
local maxRange = Config.projectileSpeed * Config.projectileTimeToLive
local botHeightAdjustment = 1.6
local blueprint_f18 = nil

ResourceManager:RegisterInstanceLoadHandler(Guid('3EABB4EF-4003-11E0-8ACA-C41D37DB421C'), Guid('C81F8757-E6D2-DF2D-1CFE-B72B4F74FE98'), function(instance)
    blueprint_f18 = VehicleBlueprint(instance)
end)

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

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
            targetTable[player.id] = target
        break end   
    end
end

function removeTarget(player)

    if player == nil then
        return
    end

    targetTable[player.id] = nil
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
    local bot = Bots:createBot('AntiAirBot' .. (tablelength(antiAirBotTable) + 1), team, SquadId.SquadNone)
    local antiAirBot = AntiAirBot()
    antiAirBot.bot = bot
    antiAirBot:spawnBot(position)
    antiAirBot.position = Vec3(position.x, position.y + botHeightAdjustment, position.z)
    antiAirBotTable[bot.id] = antiAirBot
end

function removeAntiAirBot(bot)
    if bot == nil then
        return
    end
    targetTable[bot.id] = nil
end

function botHasTarget(botId)
    
    if botId == nil then 
        return
    end

    if antiAirBotTable[botId].targetPlayerId ~= nil then
        return true
    end   

    return false
end

--[[
function targetHasBot(targetPlayerId)
    for _, target in pairs(targetTable) do
        if target.player.id == targetPlayerId then
            if #target.antiAirBotIds > 0 then
                return true
            else
                return false
            end     
        end   
    end
    return false
end
]]

function resetAllTargetAssignments()

    for _, antiAirBot in pairs(antiAirBotTable) do
        local botId = antiAirBot.bot.id
        antiAirBotTable[botId].targetPlayerId = nil
    end

    for _, target in pairs(targetTable) do
        local playerId = target.player.id
        targetTable[playerId].antiAirBotIds = {}
    end
end

function getTargetTeamCount()

    local teamCounts = {}
    
    for _, target in pairs(targetTable) do

        local teamId = target.player.teamId

        if teamCounts[teamId] == nil then
            local teamCount = TeamCount()
            teamCount.teamId = teamId
            teamCount.count = 1
            teamCounts[teamId] = teamCount
        else
            teamCounts[teamId].count = teamCounts[teamId].count + 1
        end
    end

    return teamCounts
end


function getAntiAirBotTeamCount()

    local teamCounts = {}

    for _, antiAirBot in pairs(antiAirBotTable) do
        if antiAirBot.bot.alive then

            local teamId = antiAirBot.bot.teamId

            if teamCounts[teamId] == nil then
                local teamCount = TeamCount()
                teamCount.teamId = teamId
                teamCount.count = 1
                teamCounts[teamId] = teamCount
            else
                teamCounts[teamId].count = teamCounts[teamId].count + 1
            end
        end
    end

    return teamCounts
end

function assignTargetsToBots()

    local targetsToBots = {}
    local targetTeams = getTargetTeamCount()
    local botTeams = getAntiAirBotTeamCount()

     --get the distance of each bot to each enemy target that is in range
    for _, target in pairs(targetTable) do
        for _, antiAirBot in pairs(antiAirBotTable) do
            if target.player.teamId ~= antiAirBot.bot.teamId and antiAirBot.bot.alive then       
                local targetToBot = TargetToBot()
                targetToBot.targetPlayerId = target.player.id                
                targetToBot.antiAirBotId = antiAirBot.bot.id
                targetToBot.targetPlayerTeamId = target.player.teamId
                targetToBot.antiAirBotTeamId = antiAirBot.bot.teamId
                targetToBot.distance = target:getDistance(antiAirBot.position)

                if targetToBot.distance <= maxRange then
                    table.insert(targetsToBots, targetToBot)
                end        
            end
        end
    end  

    --assign bots their closest available target
    for _, botTeamCount in pairs(botTeams) do
        for j = 1, botTeamCount.count do

            local smallestDistance = nil
            local tbIdx = 0

            for k = 1, tablelength(targetsToBots) do
                if botTeamCount.teamId == targetsToBots[k].antiAirBotTeamId and not botHasTarget(targetsToBots[k].antiAirBotId) then
                    local tId = targetsToBots[k].targetPlayerId
                    local ttId = targetsToBots[k].targetPlayerTeamId
                    local currentBotCount = targetTable[tId].antiAirBotIds
                    currentBotCount = tablelength(currentBotCount)
                    local maxBotsPerTarget = 0

                    if botTeamCount.count <= targetTeams[ttId].count then
                        maxBotsPerTarget = 1
                    else
                        maxBotsPerTarget = botTeamCount.count / targetTeams[ttId].count
                        local rest = maxBotsPerTarget % 1
                        maxBotsPerTarget = maxBotsPerTarget - rest
                        rest = rest * targetTeams[ttId].count

                        --round maxBotsPerTarget and rest to make sure they are an integer
                        maxBotsPerTarget = maxBotsPerTarget + 0.5 - (maxBotsPerTarget + 0.5) % 1
                        rest = rest + 0.5 - (rest + 0.5) % 1
                    
                        --wenn target nicht in targetsToBots dann count - 1





                        if rest ~= 0 and j > (botTeamCount.count - rest) then
                            maxBotsPerTarget = maxBotsPerTarget + 1
                        end            
                    end

                    if currentBotCount < maxBotsPerTarget then
                        if smallestDistance == nil then
                            smallestDistance = targetsToBots[k].distance
                            tbIdx = k
                        elseif targetsToBots[k].distance < smallestDistance then
                            smallestDistance = targetsToBots[k].distance
                            tbIdx = k
                        end    
                    end
                end
            end

            if targetsToBots[tbIdx] ~= nil then
                local bId = targetsToBots[tbIdx].antiAirBotId
                local tId = targetsToBots[tbIdx].targetPlayerId
                antiAirBotTable[bId].targetPlayerId = tId
                table.insert(targetTable[tId].antiAirBotIds, bId)
            else
            break end        
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

    aRefreshTime = aRefreshTime + deltaTime

    if aRefreshTime >= aRefreshRate then
        resetAllTargetAssignments()
        if tablelength(targetTable) > 0 and tablelength(antiAirBotTable) > 0 then
            assignTargetsToBots()
        end
        aRefreshTime = 0    
    end
end)

Events:Subscribe('Bot:Update', function(bot, deltaTime)

    --aim bots at their assigned target and fire
    local bId = bot.id

    if antiAirBotTable[bId] ~= nil and bot.alive then
        antiAirBotTable[bId].deltaTime = antiAirBotTable[bId].deltaTime + deltaTime

        if antiAirBotTable[bId].deltaTime >= bRefreshRate then
            if botHasTarget(bId) then
                local tId = antiAirBotTable[bId].targetPlayerId		
                local trans = antiAirBotTable[bId].bot.soldier.worldTransform.trans    
                antiAirBotTable[bId].position = Vec3(trans.x, trans.y + botHeightAdjustment, trans.z)

                if targetTable[tId] ~= nil then
                    local interceptPos = targetTable[tId]:getInterceptingPosition(antiAirBotTable[bId].position)

                    if interceptPos ~= nil then
                        antiAirBotTable[bId].aimPosition = interceptPos
                    else
                        antiAirBotTable[bId].aimPosition = targetTable[tId].player.soldier.worldTransform.trans
                    end

                    antiAirBotTable[bId]:aimYaw()
                    antiAirBotTable[bId]:aimPitch()    
                    bot.input:SetLevel(EntryInputActionEnum.EIAFire, 1)                                  
                end
            end
            antiAirBotTable[bId].deltaTime = 0
        else
            bot.input:SetLevel(EntryInputActionEnum.EIAFire, 0)
        end
    end
  
    --kill test targets after the specified amount of time
    if bot.name == 'TargetBot' and targetTable[bId] ~= nil then                

        targetTable[bId].timeAlive = targetTable[bId].timeAlive + deltaTime

        if targetTable[bId].timeAlive >= Config.targetBotTimeToLive then     
            local soldier = targetTable[bId].player.soldier
            local vehicle = targetTable[bId].vehicle
            soldier:Kill()
            vehicle:Destroy()
        end
    end
end)