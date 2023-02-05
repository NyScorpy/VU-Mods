require('presets')
require('alias')
require('admin')
json = require 'json'

weaponUnlocks = {}
allKits = {}

local medicbagGuid = Guid('00F16262-38F3-45F0-B577-C243CDB10A9E')
local ammobagGuid = Guid('D78EB213-CCB5-43FE-B148-E581575036B4')
local ammobagUSUnlockPartGuid = Guid('8B6DC9E1-1865-4CE6-8017-B07001251BF5')
local unusedRUEngineerGuid = Guid('6A660595-B630-47C1-BB70-F7D517E76B77')
local unusedRUReconGuid = Guid('9109722F-CEB8-48EF-9C13-DB2D2DFA0851')
local defaultPreset = nil

Console:Register('list', 'lists all available presets', function()
	if not isAdmin() then
		return 'you dont have permission to use this command, check the client/admin.lua file to give yourself permission if you are the server owner/admin'
	end

	for presetName, preset in pairs(presets) do
		print(presetName)
	end
end)

Console:Register('applyPreset', 'applies a preset to all players', function(args)
	if not isAdmin() then
		return 'you dont have permission to use this command, check the client/admin.lua file to give yourself permission if you are the server owner/admin'
	end

	if #args ~= 1 then
		return 'Usage: selectableunlocks.applyPreset <presetName>'
	end

	local presetName = args[1]

	if presets[presetName] == nil then
		return 'invalid preset: ' .. tostring(presetName)
	end

	NetEvents:Send('AdminApplyPreset', presetName)
end)

NetEvents:Subscribe('BroadcastApplyPreset', function(presetName)
	defaultPreset = presetName
	ApplyPreset(presetName)
end)

NetEvents:Subscribe('InitialDefaultPresetSend', function(defaultPresetName)
	defaultPreset = defaultPresetName
end)

function isAdmin()
	local player = PlayerManager:GetLocalPlayer()
	
	for _, admin in pairs(admins) do
		if admin == player.name then
			return true
		end
	end
	return false
end

function InitKits()
	local kits = {}
	table.insert(kits, 'Gameplay/Kits/USAssault')
	table.insert(kits, 'Gameplay/Kits/USEngineer')
	table.insert(kits, 'Gameplay/Kits/USSupport')
	table.insert(kits, 'Gameplay/Kits/USRecon')
	table.insert(kits, 'Gameplay/Kits/RUAssault')
	table.insert(kits, 'Gameplay/Kits/RUEngineer')
	table.insert(kits, 'Gameplay/Kits/RUSupport')
	table.insert(kits, 'Gameplay/Kits/RURecon')

	local altKits = {}
	table.insert(altKits, 'Gameplay/Kits/USAssault_XP4')
	table.insert(altKits, 'Gameplay/Kits/USEngineer_XP4')
	table.insert(altKits, 'Gameplay/Kits/USSupport_XP4')
	table.insert(altKits, 'Gameplay/Kits/USRecon_XP4')
	table.insert(altKits, 'Gameplay/Kits/RUAssault_XP4')
	table.insert(altKits, 'Gameplay/Kits/RUEngineer_XP4')
	table.insert(altKits, 'Gameplay/Kits/RUSupport_XP4')
	table.insert(altKits, 'Gameplay/Kits/RURecon_XP4')

	for i in pairs(weaponUnlocks) do
		weaponUnlocks[i] = nil
	end

	for i in pairs(allKits) do
		allKits[i] = nil
	end

	for _, kit in pairs(kits) do
		local veniceSoldierAsset = ResourceManager:SearchForDataContainer(kit)

		if veniceSoldierAsset == nil then
			print('kit ' .. kit .. ' not found, trying alt kits...')

			for i in pairs(allKits) do
				allKits[i] = nil
			end

			for _, altKit in pairs(altKits) do
				veniceSoldierAsset = ResourceManager:SearchForDataContainer(altKit)

				if veniceSoldierAsset == nil then
					print('alt kit ' .. altKit .. ' not found')
					print('Initialisation failed!')
					return
				end

				print('found alt kit ' .. altKit)
				veniceSoldierAsset = VeniceSoldierCustomizationAsset(veniceSoldierAsset)
				table.insert(allKits, veniceSoldierAsset)
			end
		break end

		print('found kit ' .. kit)
		veniceSoldierAsset = VeniceSoldierCustomizationAsset(veniceSoldierAsset)
		table.insert(allKits, veniceSoldierAsset)
	end
end

function InitWeaponUnlocks()
	for _, veniceSoldierAsset in pairs(allKits) do
		local customizationTable = CustomizationTable(veniceSoldierAsset.weaponTable)
        
        for _, unlockPart in pairs(customizationTable.unlockParts) do
            local customizationUnlockParts = CustomizationUnlockParts(unlockPart)
            local categoryId = customizationUnlockParts.uiCategorySid

            if categoryId == 'ID_M_SOLDIER_PRIMARY' or categoryId == 'ID_M_SOLDIER_SECONDARY' or
				categoryId == 'ID_M_SOLDIER_GADGET1' or categoryId == 'ID_M_SOLDIER_GADGET2' or
				categoryId == 'GADGET1' or categoryId == 'ID_WEAPON_CATEGORYGADGET1' or
				customizationUnlockParts.instanceGuid == ammobagUSUnlockPartGuid then
				
                for _, unlockAsset in pairs(customizationUnlockParts.selectableUnlocks) do
					if unlockAsset:Is('SoldierWeaponUnlockAsset') then
						local weaponUnlock = SoldierWeaponUnlockAsset(unlockAsset)
						local unlockName = weaponUnlock.name:gsub(".+/.+/U_", "")

						if aliasTable[unlockName] ~= nil then
							unlockName = aliasTable[unlockName]
						end

						if weaponUnlocks[unlockName] == nil then
							--print('adding ' .. unlockName .. ' to weaponUnlocks')
							weaponUnlocks[unlockName] = weaponUnlock							
						end
					end
                end
            else
                --print('unchecked categoryId for guid ' .. tostring(customizationUnlockParts.instanceGuid) .. ' -> ' .. tostring(categoryId))
            end
        end
	end
end

function ApplyUnlock(veniceSoldierAsset, presetWeapon, presetWeaponData, categoryId, unlockParts)
	local team = veniceSoldierAsset.name
	local classLabel = veniceSoldierAsset.labelSid
	local classCheck = false
	local teamCheck = false
	local categoryCheck = false

	--get the index of the unlock, returns -1 if the value is not found
	local index = unlockParts.selectableUnlocks:index_of(weaponUnlocks[presetWeapon])

	if string.find(team, 'US') then
		teamCheck = presetWeaponData.USTeam
		team = 'US'
	elseif string.find(team, 'RU') then
		teamCheck = presetWeaponData.RUTeam
		team = 'RU'
	else
		print('cant find team for string ' .. team)
	end

	if classLabel == 'ID_M_ASSAULT' then
		classCheck = presetWeaponData.Assault
	elseif classLabel == 'ID_M_ENGINEER' then
		classCheck = presetWeaponData.Engineer
	elseif classLabel == 'ID_M_SUPPORT' then
		classCheck = presetWeaponData.Support
	elseif classLabel == 'ID_M_RECON' then
		classCheck = presetWeaponData.Recon
	else
		print('unasigned classLabel: ' .. classLabel)
	end

	if categoryId == 'ID_M_SOLDIER_PRIMARY' then
		categoryCheck = presetWeaponData.WeaponSlot1
	elseif categoryId == 'ID_M_SOLDIER_SECONDARY' then
		categoryCheck = presetWeaponData.WeaponSlot2
	elseif (categoryId == 'ID_M_SOLDIER_GADGET1' or categoryId == 'ID_WEAPON_CATEGORYGADGET1') or
			categoryId == 'GADGET1' or unlockParts.instanceGuid == ammobagUSUnlockPartGuid then
		categoryCheck = presetWeaponData.GadgetSlot1
	elseif categoryId == 'ID_M_SOLDIER_GADGET2' then
		categoryCheck = presetWeaponData.GadgetSlot2
	else
		--print('unasigned categoryId: ' .. tostring(unlockParts.instanceGuid) .. ' -> ' .. categoryId)
		return
	end

	if classCheck and teamCheck and categoryCheck then
		--special cases to prevent duplicate unlocks
		--prevent unlocks that are not the Medicbag from being added to the Medicbag CustomizationUnlockParts
		if classLabel == 'ID_M_ASSAULT' and (categoryId == 'ID_WEAPON_CATEGORYGADGET1' or categoryId == 'GADGET1') and
			weaponUnlocks[presetWeapon].instanceGuid ~= medicbagGuid then
			return
		end

		--prevent Medicbag beeing added to the CustomizationUnlockParts of all other unlocks of this category
		if classLabel == 'ID_M_ASSAULT' and categoryId == 'ID_M_SOLDIER_GADGET1' and weaponUnlocks[presetWeapon].instanceGuid == medicbagGuid then
			return
		end

		--prevent unlocks that are not the Ammobag from being added to the Ammobag CustomizationUnlockParts
		if classLabel == 'ID_M_SUPPORT' and (unlockParts.instanceGuid == ammobagUSUnlockPartGuid or categoryId == 'GADGET1') and
			weaponUnlocks[presetWeapon].instanceGuid ~= ammobagGuid then
			return
		end

		--prevent Ammobag beeing added to the CustomizationUnlockParts of all other unlocks of this category
		if classLabel == 'ID_M_SUPPORT' and categoryId == 'ID_M_SOLDIER_GADGET1' and weaponUnlocks[presetWeapon].instanceGuid == ammobagGuid then
			return
		end

		--prevent unlocks from being added to unused RU Engineer CustomizationUnlockParts
		if unlockParts.instanceGuid == unusedRUEngineerGuid then
			return
		end

		--prevent unlocks from being added to unused RU Recon CustomizationUnlockParts
		if unlockParts.instanceGuid == unusedRUReconGuid then
			return
		end


		--if the SelectableUnlocks array does not contain the unlock then add it
		if index == -1 then
			--print('add weapon=' .. presetWeapon .. ' class=' .. classLabel .. ' categoryId=' .. categoryId .. ' team=' .. team)
			unlockParts.selectableUnlocks:add(weaponUnlocks[presetWeapon])
		else
			--print('already contains weapon=' .. presetWeapon .. ' class=' .. classLabel .. ' categoryId=' .. categoryId .. ' team=' .. team)
		end
	else
		--remove unlock from SelectableUnlocks
		if index ~= -1 then
			--print('remove weapon=' .. presetWeapon .. ' class=' .. classLabel .. ' categoryId=' .. categoryId .. ' team=' .. team)
			unlockParts.selectableUnlocks:erase(index)
		end
	end
end

function ApplyPreset(presetName)
	if presets[presetName] ~= nil then
		print('applying preset: ' .. presetName)
		local preset = json.decode(presets[presetName])

		for _, veniceSoldierAsset in pairs(allKits) do
			local customizationTable = CustomizationTable(veniceSoldierAsset.weaponTable)

			for _, unlockPart in pairs(customizationTable.unlockParts) do
				local unlockParts = CustomizationUnlockParts(unlockPart)
				unlockParts:MakeWritable()
				local categoryId = unlockParts.uiCategorySid
				
				for presetWeapon, presetWeaponData in pairs(preset) do
					ApplyUnlock(veniceSoldierAsset, presetWeapon, presetWeaponData, categoryId, unlockParts)
				end
			end
		end
	else
		print('preset ' .. tostring(presetName) .. ' not found!')
	end
end

Events:Subscribe('Level:Loaded', function()
	InitKits()
	InitWeaponUnlocks()
	ApplyPreset(defaultPreset)
end)
