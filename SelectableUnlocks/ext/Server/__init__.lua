require('config')

NetEvents:Subscribe('AdminApplyPreset', function(player, presetName)
    print(player.name .. ' changed the preset to ' .. presetName)
    defaultPreset = presetName
    NetEvents:Broadcast('BroadcastApplyPreset', presetName)
end)

Events:Subscribe('Player:Authenticated', function(player)
    if player ~= nil then
        NetEvents:SendTo('InitialDefaultPresetSend', player, defaultPreset)
    else
        print('player is nil')
    end
end)
