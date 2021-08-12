Config = {
	maxRange = 700,						--maximum range radius
	bulletSpeed = 900,					--bullet speed of the AA -> BF3 Default = 900
	spreadMinAngle = 0.2,				--minimum Angle of the AA bullet spread -> BF3 Default = 0.20000000298
	spreadMaxAngle = 0.6,				--maximum Angle of the AA bullet spread -> BF3 Default = 1.0
	rateOfFire = 2000,					--firerate of the AA -> BF3 Default = 2000
	clientFireRateMultiplier = 0.6,		--adjust the amount of rendered tracers -> BF3 Default = 0.10000000149
	tracersLightUp = true,				--set true make AA tracers light up
	botUpdateInterval = 0,				--update interval for bots, increasing this value will improve perfromance but also decrease the accuracy
	targetAssignInterval = 1,			--interval within which targets are assigned to the bots
	spawnCheckInterval = 10,			--interval within which it is checked if the bots are still spawned
	
	--don't change these
	levelLoadedDelayTime = 5,
	maxYawPerFrame = 0.11019,
	maxPitchPerFrame = 0.00776,
	fireYawOffset = 0.20944,
	firePitchOffset = 0.0523599,
	debugMode = false
}