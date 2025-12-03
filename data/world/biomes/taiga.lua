-- Taiga Biome Definition
-- Cold + Dry biome with snowy forests

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.game.registries.biomes"

BiomesRegistry:register({
    id = 2,
    name = "Taiga",
    temperature = "cold",
    humidity = "dry",

    -- Surface block configuration
    surface = BlockRef.MUD,
    subsurface = BlockRef.DIRT,
})
