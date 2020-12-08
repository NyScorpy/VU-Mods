require('__shared/Config')

--C4
ResourceManager:RegisterInstanceLoadHandler(Guid('910AD7C5-2558-11E0-96DC-FF63A5537869'), Guid('09DCA5BB-BB2E-4EC6-B07F-5F74863EB458'), function(instance)
	local explosionPackEntityData  = ExplosionPackEntityData (instance)
	explosionPackEntityData:MakeWritable()
	explosionPackEntityData.maxCount = Config.maxC4Count

	if Config.despawnC4OnDeath then
		explosionPackEntityData.timeToLiveOnPlayerDeath = 1
	else
		explosionPackEntityData.timeToLiveOnPlayerDeath = 0
	end
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('90D317AC-2554-11E0-9BE1-9E3A551FF0D1'), Guid('6CF717B6-188A-4AE7-A1D2-CC1A2333C0D7'), function(instance)
	local firingFunctionData = FiringFunctionData(instance)
	firingFunctionData:MakeWritable()
	firingFunctionData.ammo.numberOfMagazines = Config.ammoCountC4
end)

--AT-Mine
ResourceManager:RegisterInstanceLoadHandler(Guid('49F4451D-D64E-45E5-BC96-B39CE8BC4D10'), Guid('D936971A-354B-49B7-BCCA-4FE01B68D395'), function(instance)
	local explosionPackEntityData  = ExplosionPackEntityData (instance)
	explosionPackEntityData:MakeWritable()
	explosionPackEntityData.maxCount = Config.maxAtMineCount

	if Config.despawnAtMineOnDeath then
		explosionPackEntityData.timeToLiveOnPlayerDeath = 1
	else
		explosionPackEntityData.timeToLiveOnPlayerDeath = 0
	end
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('B38C8E78-EBE6-11DF-8768-F4F1C9378C27'), Guid('D1110C87-5913-43A4-A47F-04AD47B0C611'), function(instance)
	local firingFunctionData = FiringFunctionData(instance)
	firingFunctionData:MakeWritable()
	firingFunctionData.ammo.numberOfMagazines = Config.ammoCountAtMine
end)

--Claymore
ResourceManager:RegisterInstanceLoadHandler(Guid('8709A814-1FF9-11E0-8A74-C88A4F19AAB4'), Guid('AA3BA4F5-2F8E-65FD-016A-D1E6F8C870FB'), function(instance)
	local explosionPackEntityData  = ExplosionPackEntityData (instance)
	explosionPackEntityData:MakeWritable()
	explosionPackEntityData.maxCount = Config.maxClaymoreCount

	if Config.despawnClaymoreOnDeath then
		explosionPackEntityData.timeToLiveOnPlayerDeath = 1
	else
		explosionPackEntityData.timeToLiveOnPlayerDeath = 0
	end
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('D9EAFB20-1357-11E0-B5EB-8AEE7FB8A0AF'), Guid('526C78FC-D2CA-491B-9D18-1EDEFB10A762'), function(instance)
	local firingFunctionData = FiringFunctionData(instance)
	firingFunctionData:MakeWritable()
	firingFunctionData.ammo.numberOfMagazines = Config.ammoCountClaymore
end)