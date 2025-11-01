local Block = require("world.block")

local Blocks = {
    --                       R    G    B    A    [0-1]
    grass = Block("grass", { 0.2, 0.6, 0.2, 1.0 }),
    dirt  = Block("dirt",  { 0.6, 0.3, 0.1, 1.0 }),
    stone = Block("stone", { 0.5, 0.52, 0.55, 1.0 }),
}

return Blocks
