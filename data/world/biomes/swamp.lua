-- Swamp Biome Definition
-- Warm + Wet biome with muddy terrain

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 7,
    name = "Swamp",
    temperature = "warm",
    humidity = "wet",
    
    -- Surface block configuration
    surface = BlockRef.GRASS,
    subsurface = BlockRef.MUD,
    
    -- Underground block weights (percentages, auto-normalized)
    underground = {
        { block = BlockRef.STONE,     weight = 25 },
        { block = BlockRef.MUD,       weight = 25 },
        { block = BlockRef.CLAY,      weight = 20 },
        { block = BlockRef.LIMESTONE, weight = 12 },
        { block = BlockRef.GRANITE,   weight = 8 },
        { block = BlockRef.SLATE,     weight = 5 },
        { block = BlockRef.GRAVEL,    weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
})
