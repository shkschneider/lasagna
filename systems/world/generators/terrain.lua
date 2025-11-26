local noise = require "core.noise"
local Registry = require "registries"
local BlocksRegistry = require "registries.blocks"
local BLOCKS = Registry.blocks()

local Generator = {}

function Generator.seed(seed)
    assert(type(seed) == "number")
    noise.seed(seed)
end

-- Get ore blocks for generation (cached after first call)
-- NOTE: This assumes all blocks are registered during initialization
-- before any world generation occurs (which is currently the case)
-- Ore blocks are returned sorted by ID for deterministic ordering
local ore_blocks_cache = nil
local function get_ore_blocks()
    if not ore_blocks_cache then
        ore_blocks_cache = BlocksRegistry:get_ore_blocks()
    end
    return ore_blocks_cache
end

-- Constants
local SURFACE_HEIGHT_RATIO = 0.75
local BASE_FREQUENCY = 0.02
local BASE_AMPLITUDE = 15
local DIRT_MIN_DEPTH = 5
local DIRT_MAX_DEPTH = 15


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

function dirt_and_grass(column_data, world_col, z, base_height, world_height)
    local dirt_depth = DIRT_MIN_DEPTH + math.floor((DIRT_MAX_DEPTH - DIRT_MIN_DEPTH) *
        (noise.perlin2d(world_col * 0.05, z * 0.1) + 1) / 2)
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
