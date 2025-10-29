-- blocks.lua
-- Thin initializer that registers named block prototypes using block.lua.
-- This module keeps a small, data-first structure: it creates prototypes and
-- exposes an ordered list for inventories/UI.
local Block = require("block")

local Blocks = {}

-- Define block types (data-first). These call Block.load() and store prototypes on Blocks.
Blocks.grass = Block.load("grass", {0.2, 0.6, 0.2, 1.0})
Blocks.dirt  = Block.load("dirt",  {0.6, 0.3, 0.1, 1.0})
Blocks.stone = Block.load("stone", {0.5, 0.52, 0.55, 1.0})

-- Helper: return ordered list of block prototypes (useful for inventories)
function Blocks.list()
    return { Blocks.grass, Blocks.dirt, Blocks.stone }
end

return Blocks