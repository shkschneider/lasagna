local Block = require("world.block")
local T = require("data.theme")

local Blocks = {
    grass = Block("grass", T.grass),
    dirt = Block("dirt",  T.dirt),
    cobblestone = Block("cobblestone", T.cobblestone),
    stone = Block("stone", T.stone),
    bedrock = Block("bedrock", T.bedrock),
}

return Blocks
