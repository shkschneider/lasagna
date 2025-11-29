-- Savanna Biome Definition
-- Warm + Dry biome with sparse vegetation

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 8,
    name = "Savanna",
    temperature = "warm",
    humidity = "dry",
    
    -- Surface block configuration
    surface = BlockRef.SAND,
    subsurface = BlockRef.SANDSTONE,
    
    -- Underground block weights (percentages, auto-normalized)
    underground = {
        { block = BlockRef.STONE,     weight = 35 },
        { block = BlockRef.SANDSTONE, weight = 20 },
        { block = BlockRef.LIMESTONE, weight = 20 },
        { block = BlockRef.GRANITE,   weight = 10 },
        { block = BlockRef.SLATE,     weight = 8 },
        { block = BlockRef.GRAVEL,    weight = 5 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
})
