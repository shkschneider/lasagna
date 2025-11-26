-- World generation orchestrator
-- Loads configuration from data/world/*.json and orchestrates terrain/ore generation

local noise = require "core.noise"
local json = require "core.json"

-- Load configuration from JSON
local config = json.load("data/world/config.json")

-- Configuration from JSON
local SURFACE_HEIGHT_RATIO = config.surface_height_ratio
local BASE_FREQUENCY = config.base_frequency
local BASE_AMPLITUDE = config.base_amplitude
local LAYER_HEIGHT_ADJUSTMENTS = config.layer_height_adjustments

local function calculate_surface_height(col, z, world_height)
    local noise_val = noise.octave_perlin2d(col * BASE_FREQUENCY, z * 0.1, 4, 0.5, 2.0)
    local base_height = math.floor(world_height * SURFACE_HEIGHT_RATIO + noise_val * BASE_AMPLITUDE)
    -- Layer-specific height adjustments from config
    local adjustment = LAYER_HEIGHT_ADJUSTMENTS[tostring(z)] or 0
    base_height = base_height + adjustment
    return base_height
end

local here = (...):gsub("%.init$", "") .. "."
return function(column_data, world_col, z, world_height)
    local base_height = calculate_surface_height(world_col, z, world_height)
    require(here .. "terrain")(column_data, world_col, z, base_height, world_height)
    require(here .. "ores")(column_data, world_col, z, base_height, world_height)
end
