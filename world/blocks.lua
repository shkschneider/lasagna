-- blocks.lua
-- Thin initializer that registers named block prototypes using world.block.
-- Creates prototypes by calling the Block constructor (Block(name, color)).
local Block = require("world.block")

local Blocks = {
    grass = Block("grass", {0.2, 0.6, 0.2, 1.0}),
    dirt  = Block("dirt",  {0.6, 0.3, 0.1, 1.0}),
    stone = Block("stone", {0.5, 0.52, 0.55, 1.0}),
}

return Blocks