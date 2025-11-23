-- Omnitool component
-- Mining tier

require "lib"

local Omnitool = {}

local TIER_MIN = 1
local TIER_MAX = 4

function Omnitool.new(tier)
    tier = tier or 1
    assert(type(tier) == "number")
    assert(tier >= TIER_MIN and tier <= TIER_MAX)
    return {
        id = "omnitool",
        name = "OmniTool",
        tier = tier,
        min = TIER_MIN,
        max = TIER_MAX,
        tostring = function(self)
            return string.format("%d/%d", self.tier, TIER_MAX)
        end
    }
end

return Omnitool
