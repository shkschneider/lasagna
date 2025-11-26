-- Ore Generator
-- Places ore veins in stone based on noise and depth

local noise = require "core.noise"
local Registry = require "registries"
local BlocksRegistry = require "registries.blocks"
local BLOCKS = Registry.blocks()

-- Get ore blocks for generation (cached after first call)
local ore_blocks_cache = nil
local function get_ore_blocks()
    if not ore_blocks_cache then
        ore_blocks_cache = BlocksRegistry:get_ore_blocks()
    end
    return ore_blocks_cache
end

return function(column_data, world_col, z, base_height, world_height)
    local ore_blocks = get_ore_blocks()
    for row = base_height, world_height - 3 do
        if column_data[row] == BLOCKS.STONE then
            local depth_from_surface = row - base_height
            for _, ore_block in ipairs(ore_blocks) do
                local gen = ore_block.ore_gen
                local in_range = depth_from_surface >= gen.min_depth and
                                 (gen.max_depth == math.huge or depth_from_surface <= gen.max_depth)
                if in_range then
                    local ore_noise = noise.perlin3d(
                        world_col * gen.frequency,
                        row * gen.frequency,
                        z * gen.frequency + gen.offset
                    )
                    if ore_noise > gen.threshold then
                        column_data[row] = ore_block.id
                    end
                end
            end
        end
    end
end
