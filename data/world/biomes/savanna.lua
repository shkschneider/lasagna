-- Savanna Biome Definition
-- Warm + Dry biome with sparse vegetation

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 8,
    name = "Savanna",
    temperature = "warm",
    humidity = "dry",

    -- Surface block configuration
    surface = BlockRef.SAND,
    subsurface = BlockRef.SANDSTONE,
})
