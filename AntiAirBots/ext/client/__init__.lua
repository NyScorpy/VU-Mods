Console:Register('spawnBot', 'Spawns an AntiAirBot.', function(args)

	if #args < 1 or #args > 4 then
		return 'Usage: _antiairbots.spawnBot_ <*team*> [*x*] [*y*] [*z*]'
	end

	local team = args[1]
	local x = tonumber(args[2])
	local y = tonumber(args[3])
	local z = tonumber(args[4])
	local teamId = TeamId[team]

	if teamId == nil then
		return 'Error: **Invalid team id specified.**'
	end
  
	if args[2] ~= nil or args[3] ~= nil or args[4] ~= nil then
		if x == nil or y == nil or z == nil then
			return 'Error: **Spawn coordinates must be numeric.**'
		end
	end

	local position = nil

	if x ~= nil and y ~= nil and z ~= nil then
		position = Vec3(x, y, z)
	end

	if position == nil and PlayerManager:GetLocalPlayer().soldier == nil then
        return 'Error: **Player is not spawned**'
    end

	NetEvents:SendLocal('AntiAirBots:Spawn', teamId, position)

	return nil
end)

Console:Register('spawnTargets', 'Spawns n Test Targets.', function(args)

	if #args ~= 5 then
		return 'Usage: _antiairbots.spawnTarget_ <*count*> <*team*> <*x*> <*y*> <*z*>'
	end

	local count = tonumber(args[1])
	local team = args[2]
	local x = tonumber(args[3])
	local y = tonumber(args[4])
	local z = tonumber(args[5])
	local teamId = TeamId[team]

	if count == nil or count < 1 then
		return 'Error: **count must be numeric and >= 1**'
	end

	if teamId == nil then
		return 'Error: **Invalid team id specified.**'
	end
  
	if x == nil or y == nil or z == nil then
		return 'Error: **Spawn coordinates must be numeric.**'
	end

	local position = Vec3(x, y, z)  
	
	NetEvents:SendLocal('Target:Spawn', count, teamId, position)

	return nil
end)

