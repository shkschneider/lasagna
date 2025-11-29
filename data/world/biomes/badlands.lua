-- Badlands Biome Definition
-- Hot + Dry biome with rocky terrain

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 9,
    name = "Badlands",
    temperature = "hot",
    humidity = "arid",

    -- Surface block configuration
    surface = BlockRef.SAND,
    subsurface = BlockRef.SANDSTONE,
})
