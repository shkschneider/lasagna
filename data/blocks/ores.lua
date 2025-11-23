local BlockRef = require "data.blocks.ids"
local BlocksRegistry = require "registries.blocks"

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
        max_depth = math.huge, -- Unbounded - spawns at any depth >= min_depth
        frequency = 0.05,
        threshold = 0.7,
        offset = 600,
    },
})
