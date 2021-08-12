local Bots = require('bots')
local AntiAirBot = require('AntiAirBot')
local Target = require('Target')
local m_Writer = require('__shared/MessageWriter')
local BotManager = class('BotManager')

function BotManager:__init()
	self.antiAirBots = {}
    self.targets = {}
    self.UsTeamId = nil
    self.RuTeamId = nil
    self.UsAAExists = false
    self.RuAAExists = false
    self.AAcheckCompleted = false
    self.levelLoaded = false
    self.initailSpawnCompleted = false
    self.spawnDelta = 0
    self.targetAssignDelta = 0
end

local vehicleNames = {}
table.insert(vehicleNames, 'f16')
table.insert(vehicleNames, 'Venom')
table.insert(vehicleNames, 'Viper')
table.insert(vehicleNames, 'AH-6 Littlebird')
table.insert(vehicleNames, 'Su35')
table.insert(vehicleNames, 'Ka-60')
table.insert(vehicleNames, 'Mi28 Havoc')
table.insert(vehicleNames, 'Wz-11')
table.insert(vehicleNames, 'F35B')
table.insert(vehicleNames, 'A10')
table.insert(vehicleNames, 'Su25')
table.insert(vehicleNames, 'GUNSHIP')

function BotManager:onLevelLoaded(levelName, gameMode)
    --adjust TeamIds for Firestorm Rush
    if levelName == 'MP_012' and gameMode == 'RushLarge0' then
        self.UsTeamId = TeamId.Team2
        self.RuTeamId = TeamId.Team1
    else
        self.UsTeamId = TeamId.Team1
        self.RuTeamId = TeamId.Team2
    end

    self.levelLoaded = true
    self.spawnDelta = 0
end

function BotManager:checkStationaryAA()
	local iterator = EntityManager:GetIterator("ServerVehicleEntity")
	local vehicleEntity = iterator:Next()

	while vehicleEntity ~= nil do
		local vehicleName = VehicleEntityData(vehicleEntity.data).controllableType

        if vehicleName == 'Vehicles/Centurion_C-RAM/Centurion_C-RAM' or vehicleName == 'Vehicles/Centurion_C-RAM/Centurion_C-RAM_Carrier' then
            self.UsAAExists = true
            m_Writer:write('US AA Exists')
        end

        if vehicleName == 'Vehicles/Pantsir/Pantsir-S1'then
            self.RuAAExists = true
            m_Writer:write('RU AA Exists')
        end
        vehicleEntity = iterator:Next()
	end
end

function BotManager:createAntiAirBot(teamId)
    if teamId == nil then 
        return
    end

    local name = 'AA Bot'

    if teamId == self.UsTeamId then
        name = 'CENTURION C-RAM Bot'
    elseif teamId == self.RuTeamId then
        name = 'PANTSIR-S1 Bot'
    end

    local bot = Bots:createBot(name, teamId, SquadId.SquadNone)
    local antiAirBot = AntiAirBot()
    antiAirBot.bot = bot
    antiAirBot:spawnBot(self.UsTeamId, self.RuTeamId)
    self.antiAirBots[bot.id] = antiAirBot
end

function BotManager:removeAntiAirBot(bot)
    if bot ~= nil then
        self.antiAirBots[bot.id] = nil
    end  
end

function BotManager:createTarget(vehicle, player)  
    if player == nil or vehicle == nil then
        return
    end

    --return if player is already in the table
    for _, target in pairs(self.targets) do
        if target.player.id == player.id then
            return
        end   
    end
    
    --add to table
    local vehicleName = VehicleEntityData(vehicle.data).nameSid

    for _, name in pairs(vehicleNames) do
        if vehicleName == name then
            local target = Target()
            target.player = player
            target.vehicle = vehicle
            self.targets[player.id] = target
        break end   
    end
end

function BotManager:removeTarget(player)
    if player ~= nil then
        self.targets[player.id] = nil
    end   
end

function BotManager:assignTargets()
    self:resetAllTargetAssignments()

    for _, antiAirBot in pairs(self.antiAirBots) do
        local targetDistance = nil

        for _, target in pairs(self.targets) do

            --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            if antiAirBot.linearTransform == nil then 
                return
            end

            local botPos = antiAirBot.linearTransform.trans

            if target.player.teamId ~= antiAirBot.bot.teamId and antiAirBot.bot.soldier ~= nil and target:isInRange(botPos) then 
                local distance = target:getDistance(botPos)

                if targetDistance == nil or distance < targetDistance then
                    targetDistance = distance
                    antiAirBot.targetPlayerId = target.player.id
                end       
            end
        end
    end  
end

function BotManager:resetAllTargetAssignments()
    if next(self.antiAirBots) == nil then
        return
    end

    for _, antiAirBot in pairs(self.antiAirBots) do
        local botId = antiAirBot.bot.id
        self.antiAirBots[botId].targetPlayerId = nil
    end
end

function BotManager:onBotUpdate(bot, deltaTime)
    --aim bots at their assigned target and fire
    local bId = bot.id

    if self.antiAirBots[bId] ~= nil and bot.soldier ~= nil then
        self.antiAirBots[bId].deltaTime = self.antiAirBots[bId].deltaTime + deltaTime

        if self.antiAirBots[bId].deltaTime >= Config.botUpdateInterval then
            self.antiAirBots[bId]:updateTransform()

            if self.antiAirBots[bId].targetPlayerId ~= nil then
                local tId = self.antiAirBots[bId].targetPlayerId

                if self.targets[tId] ~= nil then
                    self.antiAirBots[bId].aimPosition = self.targets[tId]:getInterceptingPosition(self.antiAirBots[bId].linearTransform.trans)
                    self.antiAirBots[bId].targetDistance = self.targets[tId]:getDistance(self.antiAirBots[bId].linearTransform.trans)
                    self.antiAirBots[bId].targetVelocity = self.targets[tId]:getVelocity()

                    if self.antiAirBots[bId].aimPosition ~= nil then
                        self.antiAirBots[bId]:aimYaw()
                        self.antiAirBots[bId]:aimPitch()  

                        if self.antiAirBots[bId].yawOffset <= Config.fireYawOffset and self.antiAirBots[bId].pitchOffset <= Config.firePitchOffset then
                            bot.input:SetLevel(EntryInputActionEnum.EIAFire, 1)
                        else
                            bot.input:SetLevel(EntryInputActionEnum.EIAFire, 0)
                        end
                    end                                         
                end
            else
                bot.input:SetLevel(EntryInputActionEnum.EIAFire, 0)
                bot.input:SetLevel(EntryInputActionEnum.EIARoll, 0)
                bot.input:SetLevel(EntryInputActionEnum.EIAPitch, 0)
            end
            self.antiAirBots[bId].deltaTime = 0
        end
    end
end

function BotManager:onBotUpdate_debug(bot, deltaTime)
    --destroy test targets
    if bot.name == 'TargetBot' and self.targets[bId] ~= nil then                
        self.targets[bId].timeAlive = self.targets[bId].timeAlive + deltaTime

        if self.targets[bId].timeAlive >= 45 then     
            local soldier = self.targets[bId].player.soldier
            local vehicle = self.targets[bId].vehicle
            soldier:Kill()
            vehicle:Destroy()
        end
    end
end

function BotManager:onEngineUpdate(deltaTime)
    if self.levelLoaded then
        if not self.initailSpawnCompleted then
            self.spawnDelta = self.spawnDelta + deltaTime
            
            if self.spawnDelta >= Config.levelLoadedDelayTime then
                self.spawnDelta = 0

                --wait until a player spawned before creating bots, otherwise teams of the bots are messed up for some reason
                for _, player in pairs(PlayerManager:GetPlayers()) do
                    if player.soldier ~= nil then
                        if not self.AAcheckCompleted then
                            self:checkStationaryAA()  
                            self.AAcheckCompleted = true
                        end

                        if self.UsAAExists then 
                            m_Writer:write('creating US bot')
                            self:createAntiAirBot(self.UsTeamId)
                        end
                    
                        if self.RuAAExists then 
                            m_Writer:write('creating RU bot')
                            self:createAntiAirBot(self.RuTeamId)
                        end

                        self.initailSpawnCompleted = true
                    break end
                end              
            end
        else
            self.spawnDelta = self.spawnDelta + deltaTime

            if self.spawnDelta >= Config.spawnCheckInterval then
                self.spawnDelta = 0

                for _, antiAirBot in pairs(self.antiAirBots) do
                    if antiAirBot.bot.soldier == nil then
                        m_Writer:write('spawncheck spawning bot')
                        antiAirBot:spawnBot(self.UsTeamId, self.RuTeamId)
                    end
                end
            end
        end
    
        self.targetAssignDelta = self.targetAssignDelta + deltaTime

        if self.targetAssignDelta >= Config.targetAssignInterval then
            self:assignTargets()
            self.targetAssignDelta = 0    
        end
    end
end

return BotManager