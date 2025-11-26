-- Tree Feature Definition
-- Trees are placed on grass blocks and extend upwards

local WorldRegistry = require "registries.world"

WorldRegistry:register({
    id = "tree",
    -- Probability of spawning on a valid surface block (0.0 to 1.0)
    probability = 0.02,
    -- Layers where this feature can spawn (-1, 0, 1)
    layers = { -1, 0 },
    -- Surface blocks on which this feature can spawn (by block name)
    surface = { "grass" },
    -- Shapes define the blocks to place relative to spawn point
    -- Each shape is a 2D grid: shapes[shape_index][row][col]
    -- Row 1 is the top, increasing row goes downward
    -- Spawn point (anchor) is at the bottom-center of the shape
    -- Block names: "air" = don't modify, nil = skip, others = block name
    shapes = {
        {
            { nil, "leaves", nil },
            { "leaves", "leaves", "leaves" },
            { "leaves", "wood", "leaves" },
            { nil, "wood", nil },
            { nil, "wood", nil },
        },
    },
})
