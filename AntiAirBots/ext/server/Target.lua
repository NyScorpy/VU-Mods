local Target = class('Target')
local Bots = require('bots')
--require('__shared/Config')

function Target:__init()
    self.player = nil
    self.vehicle = nil
    self.timeAlive = 0
    self.antiAirBotIds = {}
end

function Target:getDistance(botPos)

    if self.player == nil or botPos == nil or not self.player.alive then
        return
    end
  
    local targetPos = self.player.soldier.worldTransform.trans
    local distance = math.sqrt((targetPos.x - botPos.x)^2 + (targetPos.y - botPos.y)^2 + (targetPos.z - botPos.z)^2)
    return distance
end

function Target:getInterceptingPosition(botPos)

    --https://stackoverflow.com/questions/17204513/how-to-find-the-interception-coordinates-of-a-moving-target-in-3d-space

    if self.player == nil or self.vehicle == nil or botPos == nil then
        return
    end

    local P0 = self.player.soldier.worldTransform.trans
    local V0 = PhysicsEntity(self.vehicle).velocity
    local s0 = math.sqrt(V0.x^2 + V0.y^2 + V0.z^2)
    local P1 = botPos 
    local s1 = Config.projectileSpeed
  
    local a = V0.x^2 + V0.y^2 + V0.z^2 - s1^2
    local b = 2 * ((P0.x * V0.x) + (P0.y * V0.y) + (P0.z * V0.z) - (P1.x * V0.x) - (P1.y * V0.y) - (P1.z * V0.z))
    local c = P0.x^2 + P0.y^2 + P0.z^2 + P1.x^2 + P1.y^2 + P1.z^2 - (2 * P1.x * P0.x) - (2 * P1.y * P0.y) - (2 * P1.z * P0.z)
    
    local t1 = (-b + math.sqrt(b^2 - (4 * a * c))) / (2 * a)
    local t2 = (-b - math.sqrt(b^2 - (4 * a * c))) / (2 * a) 
    local t = 0

    --if t1 is nan
    if t1 ~= t1 then
        t1 = 0
    end

    --if t2 is nan
    if t2 ~= t2 then
        t2 = 0
    end

    if t1 < 0 and t2 < 0 then
        return
    end
    
    if t1 > 0 and t2 > 0 then
        if t1 < t2 then
            t = t1
        else
            t = t2
        end
    elseif t1 > 0 and t2 < 0 then
        t = t1
    elseif t2 > 0 and t1 < 0 then
        t = t2
    end

    local V = Vec3(P0.x + (V0.x * t), P0.y + (V0.y * t), P0.z + (V0.z * t))
  
    return V  
end

function Target:spawnTarget(vehicleBlueprint, team, position)

    if vehicleBlueprint == nil or team == nil or position == nil then
		return
    end

    --spawn the vehcile
    local transform = LinearTransform()	
	transform.trans = position
    
    local params = EntityCreationParams()
	params.transform = transform
    params.networked = true
    
    local vehicleEntityBus = EntityBus(EntityManager:CreateEntitiesFromBlueprint(vehicleBlueprint, params))
    local instanceId = nil

    for i, entity in pairs(vehicleEntityBus.entities) do
		entity = Entity(entity)
        entity:Init(Realm.Realm_ClientAndServer, true)

        if entity.typeInfo.name == 'ServerVehicleEntity' then
            instanceId = entity.instanceId
        end
	end

    --spawn the bot
	soldierBlueprint = ResourceManager:SearchForInstanceByGuid(Guid('261E43BF-259B-41D2-BF3B-9AE4DDA96AD2'))
	soldierKit = ResourceManager:SearchForInstanceByGuid(Guid('0A99EBDB-602C-4080-BC3F-B388AA18ADDD'))
	
	local transform = LinearTransform()
    transform.trans = Vec3(0, 0, 0)
    
    local bot = nil

    for _, player in pairs(PlayerManager:GetPlayers()) do
        if player.name == 'TargetBot' and not player.alive and player.teamId == team then
            bot = player
            Bots:spawnBot(bot, transform, CharacterPoseType.CharacterPoseType_Stand, soldierBlueprint, soldierKit, {})	
        break end
    end
    
    if bot == nil then
        bot = Bots:createBot('TargetBot', team, SquadId.SquadNone)       
	    Bots:spawnBot(bot, transform, CharacterPoseType.CharacterPoseType_Stand, soldierBlueprint, soldierKit, {})	
    end

    --enter the vehicle
    local iterator = EntityManager:GetIterator("ServerVehicleEntity")
    local vehicleEntity = iterator:Next()
        
    while vehicleEntity ~= nil do 
        local vehicleName = VehicleEntityData(vehicleEntity.data).nameSid 

		if vehicleName == 'f16' and vehicleEntity.instanceId == instanceId then
			bot:EnterVehicle(vehicleEntity, 0)
        break end
        
		vehicleEntity = iterator:Next()
    end

    bot.input.flags = EntryInputFlags.AuthoritativeMovement
    bot.input:SetLevel(EntryInputActionEnum.EIAThrottle, 1)    
end

return Target