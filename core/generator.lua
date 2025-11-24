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

-- Step 0: Calculate surface height using Perlin noise
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

-- Step 1: Fill terrain with air above surface and stone below
function Generator.fill(column_data, world_col, base_height, world_height)
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

-- Step 2: Add dirt and grass
function Generator.dirt_and_grass(column_data, world_col, z, base_height, world_height)
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

-- Step 3: Generate ore veins using 3D Perlin noise
function Generator.ore_veins(column_data, world_col, z, base_height, world_height)
    local ore_blocks = get_ore_blocks()

    for row = base_height, world_height - 3 do -- Stop before bedrock
        if column_data[row] == BLOCKS.STONE then
            local depth_from_surface = row - base_height

            -- Iterate through all registered ore blocks
            for _, ore_block in ipairs(ore_blocks) do
                local gen = ore_block.ore_gen

                -- Check if depth is within range for this ore
                -- Check math.huge first for performance (short-circuit evaluation)
                local in_range = depth_from_surface >= gen.min_depth and
                                 (gen.max_depth == math.huge or depth_from_surface <= gen.max_depth)

                if in_range then
                    -- Use world_col for noise to ensure continuity
                    local ore_noise = noise.perlin3d(
                        world_col * gen.frequency,
                        row * gen.frequency,
                        z * gen.frequency + gen.offset
                    )

                    if ore_noise > gen.threshold then
                        column_data[row] = ore_block.id
                        -- Note: Don't break - allow later ores to potentially override
                        -- This matches original behavior where last matching ore wins
                    end
                end
            end
        end
    end
end

-- Main terrain generation function that orchestrates all steps
-- column_data: the column storage [row]
-- world_col: absolute column coordinate in the world (for noise continuity)
-- z: layer index
-- world_height: height of the world
return function(column_data, world_col, z, world_height)
    -- Step 0: Calculate surface height (uses world_col for continuity)
    local base_height = calculate_surface_height(world_col, z, world_height)
    -- Step 1: Fill base terrain (air and stone)
    Generator.fill(column_data, world_col, base_height, world_height)
    -- Step 2: Add dirt and grass layers
    Generator.dirt_and_grass(column_data, world_col, z, base_height, world_height)
    -- Step 3: Generate ore veins
    Generator.ore_veins(column_data, world_col, z, base_height, world_height)

end
