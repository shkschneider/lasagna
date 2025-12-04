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
})
