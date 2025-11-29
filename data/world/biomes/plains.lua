-- Plains Biome Definition
-- Normal temperature + humidity biome with open grasslands

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 5,
    name = "Plains",
    temperature = "normal",
    humidity = "normal",
    
    -- Surface block configuration
    surface = BlockRef.GRASS,
    subsurface = BlockRef.DIRT,
    
    -- Underground block weights (percentages, auto-normalized)
    underground = {
        { block = BlockRef.STONE,     weight = 40 },
        { block = BlockRef.GRANITE,   weight = 20 },
        { block = BlockRef.LIMESTONE, weight = 15 },
        { block = BlockRef.SLATE,     weight = 10 },
        { block = BlockRef.CLAY,      weight = 5 },
        { block = BlockRef.GRAVEL,    weight = 5 },
        { block = BlockRef.MUD,       weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
})
