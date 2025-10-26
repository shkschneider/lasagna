-- Blocks module: centralizes block type definitions and shared properties.
-- Keep this file small and data-only so it's easy to extend later.
local Blocks = {
    grass = { color = {0.2, 0.6, 0.2, 1.0}, name = "grass" },
    dirt  = { color = {0.6, 0.3, 0.1, 1.0}, name = "dirt"  },
    stone = { color = {0.5, 0.52, 0.55, 1.0}, name = "stone" },
    -- player removed: player is not a world block, its color lives in player.lua
}

return Blocks