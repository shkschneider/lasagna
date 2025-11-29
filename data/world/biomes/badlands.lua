-- Badlands Biome Definition
-- Hot + Dry biome with rocky terrain

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 9,
    name = "Badlands",
    temperature = "hot",
    humidity = "arid",
    
    -- Surface block configuration
    surface = BlockRef.SAND,
    subsurface = BlockRef.SANDSTONE,
    
    -- Underground block weights (percentages, auto-normalized)
    underground = {
        { block = BlockRef.STONE,     weight = 30 },
        { block = BlockRef.SANDSTONE, weight = 25 },
        { block = BlockRef.LIMESTONE, weight = 15 },
        { block = BlockRef.GRANITE,   weight = 12 },
        { block = BlockRef.CLAY,      weight = 8 },
        { block = BlockRef.SLATE,     weight = 5 },
        { block = BlockRef.GRAVEL,    weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
})
