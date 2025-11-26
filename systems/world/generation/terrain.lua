-- Terrain generation module
-- Loads configuration from data/world/terrain.json

local noise = require "core.noise"
local json = require "core.json"
local Registry = require "registries"
local BLOCKS = Registry.blocks()

-- Load configuration from JSON
local config = json.load("data/world/terrain.json")

-- Configuration from JSON
local DIRT_MIN_DEPTH = config.dirt_min_depth
local DIRT_MAX_DEPTH = config.dirt_max_depth
local DIRT_NOISE_FREQUENCY = config.dirt_noise_frequency
local DIRT_LAYER_OFFSET = config.dirt_layer_offset


local function air_stone_bedrock(column_data, world_col, base_height, world_height)
    for row = 0, world_height - 1 do
        if row >= base_height then
            -- Underground - stone by default
            column_data[row] = BLOCKS.STONE
        else
            -- Above ground - air
            column_data[row] = BLOCKS.AIR
        end
    end
    column_data[world_height - 2] = BLOCKS.BEDROCK
    column_data[world_height - 1] = BLOCKS.BEDROCK
end

local function dirt_and_grass(column_data, world_col, z, base_height, world_height)
    local dirt_depth = DIRT_MIN_DEPTH + math.floor((DIRT_MAX_DEPTH - DIRT_MIN_DEPTH) *
        (noise.perlin2d(world_col * DIRT_NOISE_FREQUENCY, z * DIRT_LAYER_OFFSET) + 1) / 2)
    for row = base_height, math.min(base_height + dirt_depth - 1, world_height - 1) do
        if column_data[row] == BLOCKS.STONE then
            column_data[row] = BLOCKS.DIRT
        end
    end
    if base_height > 0 and base_height < world_height then
        if column_data[base_height] == BLOCKS.DIRT and
           column_data[base_height - 1] == BLOCKS.AIR then
            column_data[base_height] = BLOCKS.GRASS
        end
    end
end

return function(column_data, world_col, z, base_height, world_height)
    air_stone_bedrock(column_data, world_col, base_height, world_height)
    dirt_and_grass(column_data, world_col, z, base_height, world_height)
end
