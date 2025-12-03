-- Jungle Biome Definition
-- Hot + Wet biome with dense vegetation

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.game.registries.biomes"

BiomesRegistry:register({
    id = 6,
    name = "Jungle",
    temperature = "hot",
    humidity = "humid",

    -- Surface block configuration
    surface = BlockRef.GRASS,
    subsurface = BlockRef.MUD,
})
