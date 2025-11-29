-- Taiga Biome Definition
-- Cold + Dry biome with snowy forests

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 2,
    name = "Taiga",
    temperature = "cold",
    humidity = "dry",
    
    -- Surface block configuration
    surface = BlockRef.MUD,
    subsurface = BlockRef.DIRT,
    
    -- Underground block weights (percentages, auto-normalized)
    underground = {
        { block = BlockRef.STONE,     weight = 35 },
        { block = BlockRef.GRANITE,   weight = 25 },
        { block = BlockRef.SLATE,     weight = 15 },
        { block = BlockRef.LIMESTONE, weight = 10 },
        { block = BlockRef.GRAVEL,    weight = 8 },
        { block = BlockRef.CLAY,      weight = 5 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
})
