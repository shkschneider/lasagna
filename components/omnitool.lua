-- Omnitool Component
-- Represents the player's omnitool progression

local Omnitool = {}

function Omnitool.new()
    return {
        tier = 0,
        min = 0,
        max = 10,
        tostring = function(self)
            return string.format("Tier %d", self.tier)
        end,
    }
end

return Omnitool
