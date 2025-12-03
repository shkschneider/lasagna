-- Biome Definitions Loader
-- Loads all biome definitions from individual files

local here = (...):gsub("%.init$", "") .. "."

-- Load all biome definitions (they register themselves with BiomesRegistry)
require(here .. "tundra")
require(here .. "taiga")
require(here .. "snowy_hills")
require(here .. "forest")
require(here .. "plains")
require(here .. "jungle")
require(here .. "swamp")
require(here .. "savanna")
require(here .. "badlands")
require(here .. "desert")

-- Return the BiomesRegistry for convenience
return require("src.game.registries.biomes")
