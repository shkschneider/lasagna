-- Default block definitions
-- Blocks register themselves with the BlocksRegistry

local BlocksRegistry = require("registries.blocks")

-- Block ID constants (for backwards compatibility and easy reference)
local BlockRef = {
    AIR = 0,
    DIRT = 1,
    GRASS = 2,
    STONE = 3,
    WOOD = 4,
    COPPER_ORE = 5,
    TIN_ORE = 6,
    IRON_ORE = 7,
    COAL = 8,
    LEAD_ORE = 9,
    ZINC_ORE = 10,
    COBALT_ORE = 11,
    SAND = 12,
    BEDROCK = 13,
}

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
    tier = 0,
    drops = function() return BlockRef.STONE, 1 end,
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

-- Register Copper Ore
BlocksRegistry:register({
    id = BlockRef.COPPER_ORE,
    name = "Copper Ore",
    solid = true,
    color = {0.8, 0.5, 0.2, 1},
    tier = 1,
    drops = function() return BlockRef.COPPER_ORE, 1 end,
    ore_gen = {
        min_depth = 10,
        max_depth = 120,
        frequency = 0.07,
        threshold = 0.55,
        offset = 100,
    },
})

-- Register Tin Ore
BlocksRegistry:register({
    id = BlockRef.TIN_ORE,
    name = "Tin Ore",
    solid = true,
    color = {0.7, 0.7, 0.7, 1},
    tier = 1,
    drops = function() return BlockRef.TIN_ORE, 1 end,
    ore_gen = {
        min_depth = 10,
        max_depth = 120,
        frequency = 0.07,
        threshold = 0.55,
        offset = 200,
    },
})

-- Register Iron Ore
BlocksRegistry:register({
    id = BlockRef.IRON_ORE,
    name = "Iron Ore",
    solid = true,
    color = {0.6, 0.5, 0.4, 1},
    tier = 2,
    drops = function() return BlockRef.IRON_ORE, 1 end,
    ore_gen = {
        min_depth = 40,
        max_depth = 150,
        frequency = 0.06,
        threshold = 0.58,
        offset = 300,
    },
})

-- Register Coal
BlocksRegistry:register({
    id = BlockRef.COAL,
    name = "Coal",
    solid = true,
    color = {0.2, 0.2, 0.2, 1},
    tier = 0,
    drops = function() return BlockRef.COAL, 1 end,
    ore_gen = {
        min_depth = 5,
        max_depth = 100,
        frequency = 0.08,
        threshold = 0.5,
        offset = 0,
    },
})

-- Register Lead Ore
BlocksRegistry:register({
    id = BlockRef.LEAD_ORE,
    name = "Lead Ore",
    solid = true,
    color = {0.4, 0.4, 0.5, 1},
    tier = 2,
    drops = function() return BlockRef.LEAD_ORE, 1 end,
    ore_gen = {
        min_depth = 50,
        max_depth = 160,
        frequency = 0.06,
        threshold = 0.6,
        offset = 400,
    },
})

-- Register Zinc Ore
BlocksRegistry:register({
    id = BlockRef.ZINC_ORE,
    name = "Zinc Ore",
    solid = true,
    color = {0.6, 0.6, 0.7, 1},
    tier = 2,
    drops = function() return BlockRef.ZINC_ORE, 1 end,
    ore_gen = {
        min_depth = 50,
        max_depth = 160,
        frequency = 0.06,
        threshold = 0.6,
        offset = 500,
    },
})

-- Register Cobalt Ore
BlocksRegistry:register({
    id = BlockRef.COBALT_ORE,
    name = "Cobalt Ore",
    solid = true,
    color = {0.2, 0.4, 0.8, 1},
    tier = 4,
    drops = function() return BlockRef.COBALT_ORE, 1 end,
    ore_gen = {
        min_depth = 80,
        max_depth = 999, -- No upper limit
        frequency = 0.05,
        threshold = 0.7,
        offset = 600,
    },
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

-- Register Bedrock (unbreakable)
BlocksRegistry:register({
    id = BlockRef.BEDROCK,
    name = "Bedrock",
    solid = true,
    color = {0.1, 0.1, 0.1, 1},
    tier = 999, -- Effectively unbreakable
    drops = function() return nil, 0 end, -- No drops
})

-- Return the block IDs for easy access
return BlockRef
