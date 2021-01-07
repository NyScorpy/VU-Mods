require('__shared/Config')

--SMAW
ResourceManager:RegisterInstanceLoadHandler(Guid('BCE98CA0-17EC-11E0-8CD8-85483A75A7C5'), Guid('AB8577C5-D5F9-4A17-BEB2-2E153E171630'), function(instance)
	local firingFunctionData = FiringFunctionData(instance)
	firingFunctionData:MakeWritable()
	firingFunctionData.ammo.magazineCapacity = -1
	firingFunctionData.fireLogic.rateOfFire = Config.fireRate
	firingFunctionData.fireLogic.fireLogicType = 2
	firingFunctionData.shot.initialPosition = Vec3(0, 0, 0)
	firingFunctionData.shot.initialDirection = Vec3(0, 0, 0)
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('168F529B-17F6-11E0-8CD8-85483A75A7C5'), Guid('168F529C-17F6-11E0-8CD8-85483A75A7C5'), function(instance)
	local missileEntityData = MissileEntityData(instance)
	missileEntityData:MakeWritable()
	missileEntityData.gravity = 0
	missileEntityData.timeToLive = Config.projectileTimeToLive     
	missileEntityData.detonateOnTimeout = true
	missileEntityData.engineStrength = 9999
	missileEntityData.maxSpeed = Config.projectileSpeed       
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('BCE98CA0-17EC-11E0-8CD8-85483A75A7C5'), Guid('C7FF303B-83E4-4D97-A709-E7CBCF0E92BD'), function(instance)
	local weaponFiringData = WeaponFiringData(instance)
	weaponFiringData:MakeWritable()
	weaponFiringData.weaponSway = nil
end)
   

--RPG
ResourceManager:RegisterInstanceLoadHandler(Guid('E7F8EC1A-E8F5-11DF-AC96-84E6B0EFF32E'), Guid('7584D16E-6B77-4A7B-BEEE-15DA5EF98E2E'), function(instance)
	local firingFunctionData = FiringFunctionData(instance)
	firingFunctionData:MakeWritable()
	firingFunctionData.ammo.magazineCapacity = -1
	firingFunctionData.fireLogic.rateOfFire = Config.fireRate
	firingFunctionData.fireLogic.fireLogicType = 2
	firingFunctionData.shot.initialPosition = Vec3(0, 0, 0)
	firingFunctionData.shot.initialDirection = Vec3(0, 0, 0)
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('6C857FD9-6FB3-11DE-B35E-864CF572E1C4'), Guid('CDD3A384-8243-A258-E23D-239CC0D52698'), function(instance)
	local missileEntityData = MissileEntityData(instance)
	missileEntityData:MakeWritable()
	missileEntityData.gravity = 0
	missileEntityData.timeToLive = Config.projectileTimeToLive
	missileEntityData.detonateOnTimeout = true
	missileEntityData.engineStrength = 9999
	missileEntityData.maxSpeed = Config.projectileSpeed       
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('E7F8EC1A-E8F5-11DF-AC96-84E6B0EFF32E'), Guid('67FBD267-C608-4EEF-ADC2-4568362675D9'), function(instance)
	local weaponFiringData = WeaponFiringData(instance)
	weaponFiringData:MakeWritable()
	weaponFiringData.weaponSway = nil
end)

--[[
--Bundle mounting

Events:Subscribe('Level:LoadResources', function()
	ResourceManager:MountSuperBundle('default_settings_win32')
	ResourceManager:MountSuperBundle('globals')
	ResourceManager:MountSuperBundle('ui')
	ResourceManager:MountSuperBundle('chunks0')
	ResourceManager:MountSuperBundle('chunks1')
	ResourceManager:MountSuperBundle('chunks2')
	ResourceManager:MountSuperBundle('mpchunks')
	ResourceManager:MountSuperBundle('levels/mp_012/mp_012')
end)

Hooks:Install('ResourceManager:LoadBundles', 100, function(hook, bundles, compartment)
	if #bundles == 1 and bundles[1] == SharedUtils:GetLevelName() then
		print('Injecting bundles.')

		bundles = {
			'levels/mp_012/mp_012',
			'levels/mp_012/conquest_large',
			bundles[1]
		}

		hook:Pass(bundles, compartment)
	end
end)

Events:Subscribe('Level:RegisterEntityResources', function(levelData)
	local registry = RegistryContainer(ResourceManager:SearchForInstanceByGuid(Guid('320240BC-173A-5E32-CA75-51E15AC01313')))
	ResourceManager:AddRegistry(registry, ResourceCompartment.ResourceCompartment_Game)
end)
]]





--[[
Events:Subscribe('BundleMounter:GetBundles', function(bundles)
	Events:Dispatch('BundleMounter:LoadBundles', 'Levels/MP_012/MP_012', {
	  'Levels/MP_012/MP_012',
	  'Levels/MP_012/Conquest_Large',
	})
end)
]]