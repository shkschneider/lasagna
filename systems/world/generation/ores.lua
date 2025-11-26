-- Ore generation module
-- Ore definitions are in the blocks registry (data/blocks/ores.lua)

local noise = require "core.noise"
local Registry = require "registries"
local BlocksRegistry = require "registries.blocks"
local BLOCKS = Registry.blocks()

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

local function ore_veins(column_data, world_col, z, base_height, world_height)
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

return function(column_data, world_col, z, base_height, world_height)
    ore_veins(column_data, world_col, z, base_height, world_height)
end
