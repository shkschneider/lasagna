-- Forest Biome Definition
-- Cold + Wet biome with dense trees

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 4,
    name = "Forest",
    temperature = "normal",
    humidity = "wet",
    
    -- Surface block configuration
    surface = BlockRef.GRASS,
    subsurface = BlockRef.DIRT,
    
    -- Underground block weights (percentages, auto-normalized)
    underground = {
        { block = BlockRef.STONE,     weight = 40 },
        { block = BlockRef.GRANITE,   weight = 18 },
        { block = BlockRef.LIMESTONE, weight = 15 },
        { block = BlockRef.SLATE,     weight = 10 },
        { block = BlockRef.CLAY,      weight = 8 },
        { block = BlockRef.GRAVEL,    weight = 5 },
        { block = BlockRef.MUD,       weight = 2 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
})
