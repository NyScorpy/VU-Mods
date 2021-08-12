local botPos = nil
local botForwardPos = nil
local aimPosition = nil
local aimPitch = nil
local botPitch = nil
local targetDistance = nil
local targetVelocity = nil
local pitchTurnSpeed = nil
local yawTurnSpeed = nil

if Config.debugMode then

NetEvents:Subscribe('TestEvent', function(bp, bfp, ap, td, tv)
	botPos = bp
	botForwardPos = bfp
	aimPosition = ap
	targetDistance = td
    targetVelocity = tv
end)

NetEvents:Subscribe('PitchEvent', function(pts)
    pitchTurnSpeed = pts
end)

NetEvents:Subscribe('YawEvent', function(yts)
    yawTurnSpeed = yts
end)

Events:Subscribe('UI:DrawHud', function()
	if botPos ~= nil and botForwardPos ~= nil and aimPosition ~= nil then	
		DebugRenderer:DrawText2D(15, 325, 'distance = ' .. targetDistance, Vec4(1, 1, 1, 0.5), 1)
        DebugRenderer:DrawText2D(15, 350, 'velocity = ' .. targetVelocity, Vec4(1, 1, 1, 0.5), 1)
        DebugRenderer:DrawText2D(15, 375, 'pitchTurnSpeed = ' .. pitchTurnSpeed, Vec4(1, 1, 1, 0.5), 1)
        DebugRenderer:DrawText2D(15, 400, 'yawTurnSpeed = ' .. yawTurnSpeed, Vec4(1, 1, 1, 0.5), 1)
		DebugRenderer:DrawLine(botPos, botForwardPos, Vec4(1, 0, 0, 0.5), Vec4(1, 0, 0, 0.5))
		DebugRenderer:DrawSphere(botPos, 0.2, Vec4(1, 0, 0, 0.5), true, false)
		DebugRenderer:DrawSphere(aimPosition, 1, Vec4(1, 1, 0, 0.5), true, false)
		DebugRenderer:DrawSphere(botForwardPos, 0.5, Vec4(0, 0, 1, 0.5), true, false)
	end
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

end