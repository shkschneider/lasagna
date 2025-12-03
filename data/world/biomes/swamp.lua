-- Swamp Biome Definition
-- Warm + Wet biome with muddy terrain

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.game.registries.biomes"

BiomesRegistry:register({
    id = 7,
    name = "Swamp",
    temperature = "warm",
    humidity = "wet",

    -- Surface block configuration
    surface = BlockRef.GRASS,
    subsurface = BlockRef.MUD,
})
