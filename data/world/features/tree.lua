-- Tree Feature Definition
-- Trees are placed on grass blocks and extend upwards

local WorldRegistry = require "registries.world"

WorldRegistry:register({
    id = "tree",
    -- Probability of spawning on a valid surface block (0.0 to 1.0)
    probability = 0.05,
    -- Layers where this feature can spawn (-1, 0, 1)
    layers = { -1, 0 },
    -- Surface blocks on which this feature can spawn (by block name)
    surface = { "grass" },
    -- Shapes define the blocks to place relative to spawn point
    -- Each shape is a 2D grid: shapes[shape_index][row][col]
    -- Row 1 is the top, increasing row goes downward
    -- Spawn point (anchor) is at the bottom-center of the shape
    -- Block names: "air" = don't modify, others = block name to place
    shapes = {
        {
            { "air", "leaves", "air" },
            { "leaves", "leaves", "leaves" },
            { "leaves", "wood", "leaves" },
            { "air", "wood", "air" },
            { "air", "wood", "air" },
        },
    },
})
