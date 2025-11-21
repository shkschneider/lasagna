-- Block prototypes
-- Each block has: id, name, color, tier (mining requirement), drops

local blocks = {}

-- Block ID constants
blocks.AIR = 0
blocks.DIRT = 1
blocks.STONE = 2
blocks.WOOD = 3
blocks.COPPER_ORE = 4
blocks.TIN_ORE = 5
blocks.IRON_ORE = 6
blocks.COAL = 7

-- Block prototypes indexed by ID
blocks.prototypes = {
    [blocks.AIR] = {
        id = blocks.AIR,
        name = "Air",
        solid = false,
        color = {0, 0, 0, 0},
        tier = 0,
    },
    [blocks.DIRT] = {
        id = blocks.DIRT,
        name = "Dirt",
        solid = true,
        color = {0.55, 0.35, 0.2, 1},
        tier = 0,
        drops = function() return blocks.DIRT, 1 end,
    },
    [blocks.STONE] = {
        id = blocks.STONE,
        name = "Stone",
        solid = true,
        color = {0.5, 0.5, 0.5, 1},
        tier = 0,
        drops = function() return blocks.STONE, 1 end,
    },
    [blocks.WOOD] = {
        id = blocks.WOOD,
        name = "Wood",
        solid = true,
        color = {0.6, 0.4, 0.2, 1},
        tier = 0,
        drops = function() return blocks.WOOD, 1 end,
    },
    [blocks.COPPER_ORE] = {
        id = blocks.COPPER_ORE,
        name = "Copper Ore",
        solid = true,
        color = {0.8, 0.5, 0.2, 1},
        tier = 1,
        drops = function() return blocks.COPPER_ORE, 1 end,
    },
    [blocks.TIN_ORE] = {
        id = blocks.TIN_ORE,
        name = "Tin Ore",
        solid = true,
        color = {0.7, 0.7, 0.7, 1},
        tier = 1,
        drops = function() return blocks.TIN_ORE, 1 end,
    },
    [blocks.IRON_ORE] = {
        id = blocks.IRON_ORE,
        name = "Iron Ore",
        solid = true,
        color = {0.6, 0.5, 0.4, 1},
        tier = 2,
        drops = function() return blocks.IRON_ORE, 1 end,
    },
    [blocks.COAL] = {
        id = blocks.COAL,
        name = "Coal",
        solid = true,
        color = {0.2, 0.2, 0.2, 1},
        tier = 0,
        drops = function() return blocks.COAL, 1 end,
    },
}

function blocks.get_proto(id)
    return blocks.prototypes[id]
end

return blocks
