-- Omnitool Component
-- Represents the player's omnitool progression

local Omnitool = {}

function Omnitool.new()
    return {
        tier = 0,
        min = 0,
        max = 10,
    }
end

return Omnitool
