local TargetToBot = class('TargetToBot')

function TargetToBot:__init()
    self.antiAirBotId = nil
    self.targetPlayerId = nil
    self.targetPlayerTeamId = nil
    self.antiAirBotTeamId = nil
    self.distance = nil
end

return TargetToBot