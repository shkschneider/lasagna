-- Tundra Biome Definition
-- Cold + Dry biome with frozen terrain

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 1,
    name = "Tundra",
    temperature = "freezing",
    humidity = "arid",
    
    -- Surface block configuration
    surface = BlockRef.MUD,
    subsurface = BlockRef.DIRT,
    
    -- Underground block weights (percentages, auto-normalized)
    underground = {
        { block = BlockRef.STONE,     weight = 35 },
        { block = BlockRef.GRANITE,   weight = 25 },
        { block = BlockRef.SLATE,     weight = 20 },
        { block = BlockRef.LIMESTONE, weight = 10 },
        { block = BlockRef.GRAVEL,    weight = 5 },
        { block = BlockRef.CLAY,      weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
})
