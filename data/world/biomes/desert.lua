-- Desert Biome Definition
-- Hot + Dry biome with sandy terrain

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.registries.biomes"

BiomesRegistry:register({
    id = 10,
    name = "Desert",
    temperature = "hot",
    humidity = "arid",

    -- Surface block configuration
    surface = BlockRef.SAND,
    subsurface = BlockRef.SANDSTONE,
})
