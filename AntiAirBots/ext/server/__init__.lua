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
    antiAirBot.position = Vec3(position.x, position.y + botHeightAdjustment, position.z)
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

function botHasTarget(antiAirBotId)
    for _, antiAirBot in pairs(antiAirBotTable) do
        if antiAirBot.bot.id == antiAirBotId and antiAirBot.targetPlayerId ~= nil then
            return true
        end   
    end
    return false
end

function getTargetIndex(targetPlayerId)
    for i = 1, #targetTable do
        if targetTable[i].player.id == targetPlayerId then
            return i
        end
    end
    return 0
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

function setTargetToBot(antiAirBotId, targetPlayerId)
    for i = 1, #antiAirBotTable do
        if antiAirBotTable[i].bot.id == antiAirBotId then
            antiAirBotTable[i].targetPlayerId = targetPlayerId
        end
    end
end

function setBotsToTarget(targetPlayerId, antiAirBotId)
    for i = 1, #targetTable do
        if targetTable[i].player.id == targetPlayerId then
            table.insert(targetTable[i].antiAirBotIds, antiAirBotId)
        end
    end
end

function resetAllTargetAssignments()
    for i = 1, #antiAirBotTable do
        antiAirBotTable[i].targetPlayerId = nil
    end

    for i = 1, #targetTable do
        targetTable[i].antiAirBotIds = {}
    end
end

function getTargetTeamCount()

    local teamCounts = {}

    for i = 1, #targetTable do
        local isNewTeam = true
        local teamCount = TeamCount()
        teamCount.teamId = targetTable[i].player.teamId

        if #teamCounts == 0 then
            table.insert(teamCounts, teamCount)
        end

        for j = 1, #teamCounts do
            if targetTable[i].player.teamId == teamCounts[j].teamId then
                teamCounts[j].count = teamCounts[j].count + 1
                isNewTeam = false
            break end
        end

        if isNewTeam then
            teamCount.count = 1
            table.insert(teamCounts, teamCount)
        end
    end
    return teamCounts
end

function getAntiAirBotTeamCount()

    local teamCounts = {}

    for i = 1, #antiAirBotTable do
        if antiAirBotTable[i].bot.alive then       

            local isNewTeam = true
            local teamCount = TeamCount()
            teamCount.teamId = antiAirBotTable[i].bot.teamId

            if #teamCounts == 0 then
                table.insert(teamCounts, teamCount)
            end

            for j = 1, #teamCounts do
                if antiAirBotTable[i].bot.teamId == teamCounts[j].teamId then
                    teamCounts[j].count = teamCounts[j].count + 1
                    isNewTeam = false
                break end
            end

            if isNewTeam then
                teamCount.count = 1
                table.insert(teamCounts, teamCount)
            end
        end
    end
    return teamCounts
end

function getTeamCountIndex(table, teamId)
    for i = 1, #table do
        if table[i].teamId == teamId then
            return i
        end
    end
    return 0
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
    for i = 1, #antiAirBotTable do
        local smallestDistance = nil
        local tbIdx = 0

        for j = 1, #targetsToBots do	
            if not botHasTarget(targetsToBots[j].antiAirBotId) then
                local tIdx = getTargetIndex(targetsToBots[j].targetPlayerId)
                local currentBotCount = targetTable[tIdx].antiAirBotIds
                currentBotCount = #currentBotCount
                
                local ttIdx = getTeamCountIndex(targetTeams, targetsToBots[j].targetPlayerTeamId)
                local btIdx = getTeamCountIndex(botTeams, targetsToBots[j].antiAirBotTeamId)
                local maxBotsPerTarget = 0
            
                if botTeams[btIdx].count <= targetTeams[ttIdx].count then
                    maxBotsPerTarget = 1
                else
                    maxBotsPerTarget = botTeams[btIdx].count / targetTeams[ttIdx].count
                    maxBotsPerTarget = maxBotsPerTarget - (maxBotsPerTarget % 1)

                    if (botTeams[btIdx].count % targetTeams[ttIdx].count) ~= 0 and i >= (targetTeams[ttIdx].count + 1) then
                        maxBotsPerTarget = maxBotsPerTarget + 1
                    end
                end

                if currentBotCount < maxBotsPerTarget then
                    if smallestDistance == nil then
                        smallestDistance = targetsToBots[j].distance
                        tbIdx = j
                    elseif targetsToBots[j].distance < smallestDistance then
                        smallestDistance = targetsToBots[j].distance
                        tbIdx = j
                    end    
                end
            end
        end

        if targetsToBots[tbIdx] ~= nil then
            setTargetToBot(targetsToBots[tbIdx].antiAirBotId, targetsToBots[tbIdx].targetPlayerId)
            setBotsToTarget(targetsToBots[tbIdx].targetPlayerId, targetsToBots[tbIdx].antiAirBotId)
        else
        break end        
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
        if #targetTable > 0 and #antiAirBotTable > 0 then
            assignTargetsToBots()
        end
        aRefreshTime = 0    
    end
end)

Events:Subscribe('Bot:Update', function(bot, deltaTime)

	--aim bots at their assignet target and fire
	for i = 1, #antiAirBotTable do
		if bot.id == antiAirBotTable[i].bot.id then  
			if bot.alive then
				antiAirBotTable[i].deltaTime = antiAirBotTable[i].deltaTime + deltaTime
			
                if antiAirBotTable[i].deltaTime >= bRefreshRate then
                    if antiAirBotTable[i].targetPlayerId ~= nil then
						local tIdx = getTargetIndex(antiAirBotTable[i].targetPlayerId)															
						local trans = antiAirBotTable[i].bot.soldier.worldTransform.trans    
						--local botHeightAdjustment = antiAirBotTable[i].bot.input.authoritativeCameraPosition.y
						antiAirBotTable[i].position = Vec3(trans.x, trans.y + botHeightAdjustment, trans.z)
						
						if targetTable[tIdx] ~= nil then
							local interceptPos = targetTable[tIdx]:getInterceptingPosition(antiAirBotTable[i].position)

							if interceptPos ~= nil then
								antiAirBotTable[i].aimPosition = interceptPos
							else
								antiAirBotTable[i].aimPosition = targetTable[tIdx].player.soldier.worldTransform.trans
							end

							antiAirBotTable[i]:aimYaw()
                            antiAirBotTable[i]:aimPitch()    
                            bot.input:SetLevel(EntryInputActionEnum.EIAFire, 1)                                  
                        end
                    end
                    antiAirBotTable[i].deltaTime = 0
                else
                    bot.input:SetLevel(EntryInputActionEnum.EIAFire, 0)
                end
			end
		break end
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