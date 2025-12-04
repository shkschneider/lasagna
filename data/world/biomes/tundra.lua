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
})
