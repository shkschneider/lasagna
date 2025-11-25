-- Omnitool component
-- Mining tier

local OmnitoolComponent = {}

local TIER_MIN = 1
local TIER_MAX = 4

function OmnitoolComponent.new(tier)
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

return OmnitoolComponent
