local Bots = require('bots')
local m_Writer = require('__shared/MessageWriter')
local AntiAirBot = class('AntiAirBot')

function AntiAirBot:__init()
	self.bot = nil
	self.designatedTeamId = nil
	self.linearTransform = nil
	self.targetPlayerId = nil
	self.aimPosition = nil
	self.partIndex = nil
	self.deltaTime = 0
	self.targetDistance = nil
	self.targetVelocity = nil
	self.yawOffset = nil
	self.pitchOffset = nil
end

function AntiAirBot:spawnBot(UsTeamId, RuTeamId)
	if self.bot == nil then
		return
  	end
	  
	local vehicleNames = {}
	
	if self.bot.teamId == UsTeamId then
		table.insert(vehicleNames, 'Vehicles/Centurion_C-RAM/Centurion_C-RAM')
		table.insert(vehicleNames, 'Vehicles/Centurion_C-RAM/Centurion_C-RAM_Carrier')
		self.partIndex = 3
	elseif self.bot.teamId == RuTeamId then
		table.insert(vehicleNames, 'Vehicles/Pantsir/Pantsir-S1')
		self.partIndex = 1
	end

	local iterator = EntityManager:GetIterator("ServerVehicleEntity")
	local vehicleEntity = iterator:Next()

	while vehicleEntity ~= nil do
		local vehicleName = VehicleEntityData(vehicleEntity.data).controllableType

		for _, vName in pairs(vehicleNames) do
			if vehicleName == vName then
				local vehicleEntry = 0
				local controllableEntity = ControllableEntity(vehicleEntity)

				if controllableEntity:GetPlayerInEntry(vehicleEntry) == nil then
					local soldierBlueprint = ResourceManager:SearchForInstanceByGuid(Guid('261E43BF-259B-41D2-BF3B-9AE4DDA96AD2'))
					local soldierKit = ResourceManager:SearchForInstanceByGuid(Guid('0A99EBDB-602C-4080-BC3F-B388AA18ADDD'))
					local transform = LinearTransform()

    				transform.trans = Vec3(0, 0, 0)
					Bots:spawnBot(self.bot, transform, CharacterPoseType.CharacterPoseType_Stand, soldierBlueprint, soldierKit, {})	

					if self.bot.soldier ~= nil then
						self.bot:EnterVehicle(vehicleEntity, vehicleEntry)
						m_Writer:write(self.bot.name .. ' entered ' .. vName)		
					else
						m_Writer:write(self.bot.name .. ' cant enter ' .. vName .. ' - soldier is nil')
						return
					end
				else	
					m_Writer:write(vName .. ' is occupied')
				break end
			end
		end
		vehicleEntity = iterator:Next()
	end
end

function AntiAirBot:updateTransform()
	if self.bot == nil or self.bot.soldier == nil or self.bot.controlledControllable == nil then
		return
	else
		self.linearTransform = self.bot.controlledControllable.physicsEntityBase:GetPartTransform(self.partIndex):ToLinearTransform()
	end

	if Config.debugMode then
		if self.targetVelocity ~= nil and self.targetDistance ~= nil and self.linearTransform.forward ~= nil then
			local botForwardPos = self.linearTransform.trans + (self.linearTransform.forward * self.targetDistance)
			NetEvents:Broadcast('TestEvent', self.linearTransform.trans, botForwardPos, self.aimPosition, self.targetDistance, self.targetVelocity)
		end
	end
end

function AntiAirBot:calcAngle(A, B, C)
	local a = math.sqrt((C.x - B.x)^2 + (C.y - B.y)^2 + (C.z - B.z)^2)
	local b = math.sqrt((B.x - A.x)^2 + (B.y - A.y)^2 + (B.z - A.z)^2)
	local c = math.sqrt((C.x - A.x)^2 + (C.y - A.y)^2 + (C.z - A.z)^2)	
	local alpha = math.acos((a^2 - b^2 - c^2) / (-2 * b * c))
	return alpha
end

function AntiAirBot:calcTurnSpeed(offset, maxAnglePerFrame)
	if offset == 0 then
		return 0
	end
	
	local turnSpeed = 1

	if offset <= maxAnglePerFrame then
		if self.targetDistance >= 1000 then
			turnSpeed = 0.4

		elseif self.targetDistance < 1000 and self.targetDistance >= 700 then
			turnSpeed = 0.6

			if self.targetVelocity <= 200 then
				turnSpeed = 0.5

				if self.targetVelocity <= 130 then
					turnSpeed = 0.4

					if self.targetVelocity <= 80 then
						turnSpeed = 0.3
					end
				end
			end
		elseif self.targetDistance < 700 and self.targetDistance >= 400 then
			if self.targetVelocity <= 200 then
				turnSpeed = 0.85

				if self.targetVelocity <= 130 then
					turnSpeed = 0.75

					if self.targetVelocity <= 80 then
						turnSpeed = 0.6
					end
				end
			end
		elseif self.targetDistance < 400 then
			if self.targetVelocity <= 130 then
				turnSpeed = 0.7
			end
		end
	end

	return turnSpeed
end

function AntiAirBot:aimYaw()
	if self.bot == nil or self.aimPosition == nil or self.bot.soldier == nil or self.bot.controlledControllable == nil then
		return
	end

	--calculate current yaw of the vehicle
	--https://github.com/Joe91/fun-bots/blob/65e133b4f2e1bb4179399a3d04a18519e0065e0c/ext/Server/Bot.lua#L752
	local s_Pos = self.linearTransform.forward
	local s_AtanDzDx = math.atan(s_Pos.z, s_Pos.x)
	local botYaw = (s_AtanDzDx > math.pi / 2) and (s_AtanDzDx - math.pi / 2) or (s_AtanDzDx + 3 * math.pi / 2)
	
	--calculate yaw to aim at the target
	local aimPos = self.aimPosition
	local botPos = self.linearTransform.trans
	local botForwardPos = botPos + s_Pos
	local yawOffset = self:calcAngle(botPos, aimPos, botForwardPos)
	
	if yawOffset == nil then 
		return
	end

	self.yawOffset = yawOffset

	--https://math.stackexchange.com/questions/274712/calculate-on-which-side-of-a-straight-line-is-a-given-point-located
	local d = (botForwardPos.x - botPos.x) * (aimPos.z - botPos.z) - (botForwardPos.z - botPos.z) * (aimPos.x - botPos.x)
	local aimYaw = nil

    if d > 0 then
		if yawOffset + botYaw > (math.pi * 2) then
			aimYaw = yawOffset + botYaw - (math.pi * 2)
		else
			aimYaw = botYaw + yawOffset
		end
	else
		if botYaw - yawOffset < 0 then
			aimYaw = botYaw - yawOffset + (math.pi * 2)
		else
			aimYaw = botYaw - yawOffset
		end
	end

	local yawTurnSpeed = self:calcTurnSpeed(yawOffset, Config.maxYawPerFrame)

	if Config.debugMode then
		NetEvents:Broadcast('YawEvent', yawTurnSpeed)
	end

	if d > 0 then
		self.bot.input:SetLevel(EntryInputActionEnum.EIARoll, yawTurnSpeed)
	else
		self.bot.input:SetLevel(EntryInputActionEnum.EIARoll, -yawTurnSpeed)
	end
end

function AntiAirBot:aimPitch()
	if self.bot == nil or self.aimPosition == nil or self.bot.soldier == nil or self.bot.controlledControllable == nil then
		return
	end
	
	--calculate current pitch of the vehicle
	local botPos = self.linearTransform.trans
    local botForwardPos = botPos + self.linearTransform.forward
    local botPitchPos = Vec3(botForwardPos.x, botPos.y, botForwardPos.z)
	local botPitch = self:calcAngle(botPos, botForwardPos, botPitchPos)

	if botPos.y > botForwardPos.y then
        botPitch = -botPitch
    end

	--calculate pitch to aim at the target
	local aimPos = self.aimPosition
	botPitchPos = Vec3(aimPos.x, botPos.y, aimPos.z)
	local aimPitch = self:calcAngle(botPos, aimPos, botPitchPos)
	
	if aimPitch == nil or botPitch == nil then 
		return
	end
	
	if botPos.y > aimPos.y then
		aimPitch = -aimPitch
	end

	if aimPitch < botPitch then
		self.pitchOffset = botPitch - aimPitch
	else
		self.pitchOffset = aimPitch - botPitch
	end

	local pitchTurnSpeed = self:calcTurnSpeed(self.pitchOffset, Config.maxPitchPerFrame)

	if aimPitch < botPitch then
		self.bot.input:SetLevel(EntryInputActionEnum.EIAPitch, -pitchTurnSpeed)
	else
		self.bot.input:SetLevel(EntryInputActionEnum.EIAPitch, pitchTurnSpeed)
	end

	if Config.debugMode then
		NetEvents:Broadcast('PitchEvent', pitchTurnSpeed)
	end
end

return AntiAirBot