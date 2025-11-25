local BlockRef = require "data.blocks.ids"
local BlocksRegistry = require "registries.blocks"

-- Register Air
BlocksRegistry:register({
    id = BlockRef.AIR,
    name = "Air",
    solid = false,
    color = {0, 0, 0, 0},
    tier = 0,
})

-- Register Dirt
BlocksRegistry:register({
    id = BlockRef.DIRT,
    name = "Dirt",
    solid = true,
    color = {0.55, 0.35, 0.2, 1},
    tier = 0,
    drops = function() return BlockRef.DIRT, 1 end,
})

-- Register Grass
BlocksRegistry:register({
    id = BlockRef.GRASS,
    name = "Grass",
    solid = true,
    color = {0.3, 0.7, 0.2, 1},
    tier = 0,
    drops = function() return BlockRef.DIRT, 1 end,
})

-- Register Stone
BlocksRegistry:register({
    id = BlockRef.STONE,
    name = "Stone",
    solid = true,
    color = {0.5, 0.5, 0.5, 1},
    tier = 1,
    drops = function() return BlockRef.STONE, 1 end,
})

-- Register Sand
BlocksRegistry:register({
    id = BlockRef.SAND,
    name = "Sand",
    solid = true,
    color = {0.9, 0.85, 0.6, 1},
    tier = 0,
    drops = function() return BlockRef.SAND, 1 end,
})

-- Register Wood
BlocksRegistry:register({
    id = BlockRef.WOOD,
    name = "Wood",
    solid = true,
    color = {0.6, 0.4, 0.2, 1},
    tier = 0,
    drops = function() return BlockRef.WOOD, 1 end,
})

-- Register Bedrock (unbreakable)
BlocksRegistry:register({
    id = BlockRef.BEDROCK,
    name = "Bedrock",
    solid = true,
    color = {0.1, 0.1, 0.1, 1},
    tier = math.inf, -- Effectively unbreakable
    drops = function() return nil, 0 end, -- No drops
})
