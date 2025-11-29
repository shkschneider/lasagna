-- Snowy Hills Biome Definition
-- Cold biome with snow-covered hills

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 3,
    name = "Snowy Hills",
    temperature = "cold",
    humidity = "normal",
    
    -- Surface block configuration
    surface = BlockRef.SNOW,
    subsurface = BlockRef.STONE,
    
    -- Underground block weights (percentages, auto-normalized)
    underground = {
        { block = BlockRef.STONE,     weight = 40 },
        { block = BlockRef.GRANITE,   weight = 25 },
        { block = BlockRef.SLATE,     weight = 15 },
        { block = BlockRef.LIMESTONE, weight = 10 },
        { block = BlockRef.GRAVEL,    weight = 5 },
        { block = BlockRef.BASALT,    weight = 5 },
    },
})
