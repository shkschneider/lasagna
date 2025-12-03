-- Forest Biome Definition
-- Cold + Wet biome with dense trees

local BlockRef = require "data.blocks.ids"
local BiomesRegistry = require "src.game.registries.biomes"

BiomesRegistry:register({
    id = 4,
    name = "Forest",
    temperature = "normal",
    humidity = "wet",

    -- Surface block configuration
    surface = BlockRef.GRASS,
    subsurface = BlockRef.DIRT,
})
