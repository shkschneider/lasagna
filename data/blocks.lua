local Block = require("world.block")
local T = require("data.theme")

-- Create bedrock with no drop behavior
local bedrock = Block("bedrock", T.bedrock)
bedrock.drop = function(self, world, col, row, z, count)
    -- Bedrock doesn't drop anything
    return false
end

local Blocks = {
    grass = Block("grass", T.grass),
    dirt = Block("dirt",  T.dirt),
    cobblestone = Block("cobblestone", T.cobblestone),
    stone = Block("stone", T.stone),
    bedrock = bedrock,
}

return Blocks
