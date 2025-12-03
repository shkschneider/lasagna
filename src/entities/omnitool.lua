local Omnitool = {
    id = "omnitool",
    TIER_MIN = 1,
    TIER_MAX = 4,
    tostring = function(self)
        return string.format("%d/%d", self.tier, self.TIER_MAX)
    end,
}

function Omnitool.new(tier)
    tier = tier or 1
    assert(type(tier) == "number")
    assert(tier >= Omnitool.TIER_MIN and tier <= Omnitool.TIER_MAX)
    local omnitool = {
        name = "OmniTool",
        tier = tier,
        min = Omnitool.TIER_MIN,
        max = Omnitool.TIER_MAX,
    }
    return setmetatable(omnitool, { __index = Omnitool })
end

return Omnitool
