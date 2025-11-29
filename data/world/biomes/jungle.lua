-- Jungle Biome Definition
-- Hot + Wet biome with dense vegetation

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 6,
    name = "Jungle",
    temperature = "hot",
    humidity = "humid",
    
    -- Surface block configuration
    surface = BlockRef.GRASS,
    subsurface = BlockRef.MUD,
    
    -- Underground block weights (percentages, auto-normalized)
    underground = {
        { block = BlockRef.STONE,     weight = 30 },
        { block = BlockRef.GRANITE,   weight = 15 },
        { block = BlockRef.LIMESTONE, weight = 15 },
        { block = BlockRef.MUD,       weight = 15 },
        { block = BlockRef.CLAY,      weight = 12 },
        { block = BlockRef.SLATE,     weight = 8 },
        { block = BlockRef.GRAVEL,    weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
})
