-- Omnitool component
-- Mining tier

local OmnitoolComponent = {
    TIER_MIN = 1,
    TIER_MAX = 4,
}

function OmnitoolComponent.new(tier)
    tier = tier or 1
    assert(type(tier) == "number")
    assert(tier >= OmnitoolComponent.TIER_MIN and tier <= OmnitoolComponent.TIER_MAX)
    local omnitool = {
        id = "omnitool",
        name = "OmniTool",
        tier = tier,
        min = OmnitoolComponent.TIER_MIN,
        max = OmnitoolComponent.TIER_MAX,
        tostring = function(self)
            return string.format("%d/%d", self.tier, OmnitoolComponent.TIER_MAX)
        end
    }
    return setmetatable(omnitool, { __index = OmnitoolComponent })
end

return OmnitoolComponent
