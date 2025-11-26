local noise = require "core.noise"
local Registry = require "registries"
local BlocksRegistry = require "registries.blocks"
local BLOCKS = Registry.blocks()

local WorldGenerator = {}

function WorldGenerator.seed(seed)
    assert(type(seed) == "number")
    noise.seed(seed)
end

-- Constants
local SURFACE_HEIGHT_RATIO = 0.75
local BASE_FREQUENCY = 0.02
local BASE_AMPLITUDE = 15
local DIRT_MIN_DEPTH = 5
local DIRT_MAX_DEPTH = 15

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

local here = (...):gsub("%.init$", "") .. "."
return function(column_data, world_col, z, world_height)
    local base_height = calculate_surface_height(world_col, z, world_height)
    require(here .. "terrain")(column_data, world_col, z, base_height, world_height)
    require(here .. "ores")(column_data, world_col, z, base_height, world_height)
    require(here .. "nature")(column_data, world_col, z, base_height, world_height)
end
