require('__shared/Config')
local m_Writer = require('__shared/MessageWriter')

ResourceManager:RegisterInstanceLoadHandler(Guid('15A6F4C7-1700-432B-95A7-D5DE8A058ED2'), Guid('465DA0A5-F57D-44CF-8383-7F7DC105973A'), function(instance)
	local firingFunctionData = FiringFunctionData(instance)
	firingFunctionData:MakeWritable()
	firingFunctionData.overHeat.heatPerBullet = 0.0001
	firingFunctionData.dispersion[1].minAngle = Config.spreadMinAngle
	firingFunctionData.dispersion[1].maxAngle = Config.spreadMaxAngle
	firingFunctionData.shot.initialSpeed = Vec3(0, 0, Config.bulletSpeed)
	--firingFunctionData.shot.initialPosition = Vec3(0, 0, 35)
	firingFunctionData.fireLogic.rateOfFire = Config.rateOfFire
	firingFunctionData.fireLogic.clientFireRateMultiplier = Config.clientFireRateMultiplier
	m_Writer:write('patching firingFunctionData')
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('15A6F4C7-1700-432B-95A7-D5DE8A058ED2'), Guid('66C5F2C0-E97D-4850-900C-89D655E7E354'), function(instance)
	local t = (Config.maxRange * 2) / Config.bulletSpeed
	
	if t > 10 then
		t = 10
	end

	local bulletEntityData = BulletEntityData(instance)
	bulletEntityData:MakeWritable()
	bulletEntityData.timeToLive = t
	m_Writer:write('patching bulletEntityData')
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('03D35978-99D2-49E0-93C4-ED1C79F0C955'), Guid('85FBE0FB-7885-4C2D-9D55-FCFAC1F8F6C7'), function(instance)
	if Config.tracersLightUp then
		local emitterTemplateData = EmitterTemplateData(instance)
		emitterTemplateData:MakeWritable()
		emitterTemplateData.actAsPointLight = true
		emitterTemplateData.pointLightColor = Vec3(1, 0.25, 0)
		--emitterTemplateData.particleCullingFactor = 10
		--emitterTemplateData.meshCullingDistance = 10000
		m_Writer:write('patching emitterTemplateData')
	end
end)