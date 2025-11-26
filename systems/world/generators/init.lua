-- World Generator Module
-- Orchestrates terrain generation, ore placement, and future features
--
-- Generation is done in passes:
--   1. Terrain (air, stone, bedrock, dirt, grass)
--   2. Ores (coal, iron, etc.)
--   3. Features (future: trees, caves, structures, etc.)

local noise = require "core.noise"

local WorldGenerator = {}

function WorldGenerator.seed(seed)
    assert(type(seed) == "number")
    noise.seed(seed)
end

-- Constants for surface height calculation
local SURFACE_HEIGHT_RATIO = 0.75
local BASE_FREQUENCY = 0.02
local BASE_AMPLITUDE = 15

-- Calculate surface height for a given column and layer
local function calculate_surface_height(col, z, world_height)
    local noise_val = noise.octave_perlin2d(col * BASE_FREQUENCY, z * 0.1, 4, 0.5, 2.0)
    local base_height = math.floor(world_height * SURFACE_HEIGHT_RATIO + noise_val * BASE_AMPLITUDE)
    -- Layer-specific height adjustments
    if z == 1 then
        base_height = base_height + 5
    elseif z == -1 then
        base_height = base_height - 5
    end
    return base_height
end

-- Load generator passes
local here = (...):gsub("%.init$", "") .. "."

-- Main generation function
-- Called for each column to generate blocks
return function(column_data, world_col, z, world_height)
    local base_height = calculate_surface_height(world_col, z, world_height)

    -- Pass 1: Base terrain
    require(here .. "terrain")(column_data, world_col, z, base_height, world_height)

    -- Pass 2: Ore placement
    require(here .. "ores")(column_data, world_col, z, base_height, world_height)

    -- Pass 3: Features (future expansion point)
    -- Features can be added here as additional require calls:
    -- require(here .. "features.trees")(column_data, world_col, z, base_height, world_height)
    -- require(here .. "features.caves")(column_data, world_col, z, base_height, world_height)
end
