-- Desert Biome Definition
-- Hot + Dry biome with sandy terrain

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 10,
    name = "Desert",
    temperature = "hot",
    humidity = "arid",
    
    -- Surface block configuration
    surface = BlockRef.SAND,
    subsurface = BlockRef.SANDSTONE,
    
    -- Underground block weights (percentages, auto-normalized)
    underground = {
        { block = BlockRef.SANDSTONE, weight = 35 },
        { block = BlockRef.STONE,     weight = 25 },
        { block = BlockRef.LIMESTONE, weight = 20 },
        { block = BlockRef.GRANITE,   weight = 10 },
        { block = BlockRef.SLATE,     weight = 5 },
        { block = BlockRef.GRAVEL,    weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
})
