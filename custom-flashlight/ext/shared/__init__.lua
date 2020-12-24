--this mod is based on NoFate's infection Mod: https://github.com/OrfeasZ/infection/tree/38e60ebc1709a8b7586c3f44970c234d8572f45d
local flashLight1PGuid = Guid('995E49EE-8914-4AFD-8EF5-59125CA8F9CD', 'D')
local flashLight3PGuid = Guid('5FBA51D6-059F-4284-B5BB-6E20F145C064', 'D')

function patchFlashLight(instance)
	if instance == nil then
		return
	end

	local spotLight = SpotLightEntityData(instance)
	instance:MakeWritable()

	spotLight.radius = 100
	spotLight.intensity = 2
	spotLight.coneOuterAngle = 80
	spotLight.orthoWidth = 5
	spotLight.orthoHeight = 5
	spotLight.frustumFov = 50
	spotLight.castShadowsEnable = true
	spotLight.castShadowsMinLevel = QualityLevel.QualityLevel_Low

	print('Patching flashlight')
end

Events:Subscribe('Partition:Loaded', function(partition)
	for _, instance in pairs(partition.instances) do
		if instance.instanceGuid == flashLight1PGuid then
			patchFlashLight(instance)
		elseif instance.instanceGuid == flashLight3PGuid then
			patchFlashLight(instance)
		end
	end
end)

Events:Subscribe('Extension:Loaded', function()
	patchFlashLight(ResourceManager:SearchForInstanceByGuid(flashLight1PGuid))
	patchFlashLight(ResourceManager:SearchForInstanceByGuid(flashLight3PGuid))
end)