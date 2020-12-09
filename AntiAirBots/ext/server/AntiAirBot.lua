local Bots = require('bots')
local AntiAirBot = class('AntiAirBot')

function AntiAirBot:__init()
	self.bot = nil
	self.position = nil
	self.aimPosition = nil
	self.targetPlayerId = nil
	self.deltaTime = 0
end

function AntiAirBot:spawnBot(position)

  	if self.bot == nil or position == nil then
		return
  	end
	
	--US
	local soldierBlueprint = ResourceManager:SearchForInstanceByGuid(Guid('261E43BF-259B-41D2-BF3B-9AE4DDA96AD2'))
	local soldierKit = ResourceManager:SearchForInstanceByGuid(Guid('0A99EBDB-602C-4080-BC3F-B388AA18ADDD'))
	
	--RU
	if self.bot.teamId == TeamId.Team2 then
		soldierBlueprint = ResourceManager:SearchForInstanceByGuid(Guid('261E43BF-259B-41D2-BF3B-9AE4DDA96AD2'))
		soldierKit = ResourceManager:SearchForInstanceByGuid(Guid('DB0FCE83-2505-4948-8661-660DD0C64B63'))
	end

	local transform = LinearTransform()
	transform.trans = position
	Bots:spawnBot(self.bot, transform, CharacterPoseType.CharacterPoseType_Stand, soldierBlueprint, soldierKit, {})		
	self.bot.input:SetLevel(EntryInputActionEnum.EIASelectWeapon3, 1)
end

function AntiAirBot:aimYaw()

	if self.bot == nil or self.aimPosition == nil then
		return
	end

	local aimPos = self.aimPosition
	local botYaw = self.bot.input.authoritativeAimingYaw
	local botPos = self.position
	local b = 1
	local botForwardPos = botPos + (self.bot.soldier.worldTransform.forward * b)
	local a = math.sqrt((aimPos.x - botForwardPos.x)^2 + (aimPos.z - botForwardPos.z)^2)	
	local c = math.sqrt((aimPos.x - botPos.x)^2 + (aimPos.z - botPos.z)^2)	
	local alpha = math.acos((a^2 - b^2 - c^2) / (-2 * b * c))	
	
	--if alpha is nan
	if alpha ~= alpha then 
		return
	end

	--https://math.stackexchange.com/questions/274712/calculate-on-which-side-of-a-straight-line-is-a-given-point-located
	local d = (botForwardPos.x - botPos.x) * (aimPos.z - botPos.z) - (botForwardPos.z - botPos.z) * (aimPos.x - botPos.x)
	local aimYaw = nil

	if d > 0 then		
		--left
		if alpha + botYaw > (math.pi * 2) then
			aimYaw = alpha + botYaw - (math.pi * 2)
		else
			aimYaw = botYaw + alpha
		end
	else
		--right
		if botYaw - alpha < 0 then
			aimYaw = botYaw - alpha + (math.pi * 2)
		else
			aimYaw = botYaw - alpha
		end
	end

	self.bot.input.flags = EntryInputFlags.AuthoritativeAiming
	self.bot.input.authoritativeAimingYaw = aimYaw
end

function AntiAirBot:aimPitch()

	if self.bot == nil or self.aimPosition == nil then
		return
	end

	local aimPos = self.aimPosition
	local botPos = self.position
	local botPitchPos = Vec3(aimPos.x, botPos.y, aimPos.z)
	
	local b = math.sqrt((botPitchPos.x - botPos.x)^2 + (botPitchPos.y - botPos.y)^2 + (botPitchPos.z - botPos.z)^2)
	local a = math.sqrt((aimPos.x - botPitchPos.x)^2 + (aimPos.y - botPitchPos.y)^2 + (aimPos.z - botPitchPos.z)^2)
	local c = math.sqrt((aimPos.x - botPos.x)^2 + (aimPos.y - botPos.y)^2 + (aimPos.z - botPos.z)^2)	
	local alpha = math.acos((a^2 - b^2 - c^2) / (-2 * b * c))	

	--if alpha is nan
	if alpha ~= alpha then 
		return
	end
	
	local aimPitch = nil
	
	if botPos.y < aimPos.y then
		aimPitch = alpha
	else 
		aimPitch = alpha * -1
	end

	self.bot.input.flags = EntryInputFlags.AuthoritativeAiming
	self.bot.input.authoritativeAimingPitch = aimPitch
end

return AntiAirBot






