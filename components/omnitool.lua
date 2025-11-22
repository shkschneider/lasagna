-- Omnitool component
-- Mining tier

local Omnitool = {}

function Omnitool.new(tier)
    return {
        id = "omnitool",
        tier = tier or 0,
    }
end

return Omnitool
