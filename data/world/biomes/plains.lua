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
})
