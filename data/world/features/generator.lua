-- Feature Generator
-- Places registered features in the world based on their definitions

local noise = require "core.noise"
local Registry = require "registries"
local WorldRegistry = require "registries.world"
local BlocksRegistry = require "registries.blocks"
local BLOCKS = Registry.blocks()

-- Map block names to block IDs (case-insensitive)
local block_name_cache = nil
local function get_block_id_by_name(name)
    if not block_name_cache then
        block_name_cache = {}
        for id, block in BlocksRegistry:iterate() do
            if type(block) == "table" and block.name then
                block_name_cache[block.name:lower()] = id
            end
        end
    end
    return block_name_cache[name:lower()]
end

-- Check if a block is a valid surface for the feature
local function is_valid_surface(block_id, surface_names)
    local block = BlocksRegistry:get(block_id)
    if not block or not block.name then
        return false
    end
    local block_name_lower = block.name:lower()
    for _, surface_name in ipairs(surface_names) do
        if block_name_lower == surface_name:lower() then
            return true
        end
    end
    return false
end

-- Check if layer is valid for feature
local function is_valid_layer(z, feature_layers)
    for _, layer in ipairs(feature_layers) do
        if tonumber(layer) == z then
            return true
        end
    end
    return false
end

-- Calculate spawn probability using noise for deterministic placement
local function should_spawn(col, z, feature)
    local probability = feature.probability or 0.01
    -- Use feature id hash as offset for unique noise per feature type
    local id_hash = 0
    for i = 1, #feature.id do
        id_hash = id_hash + string.byte(feature.id, i) * i
    end
    -- Use a higher frequency noise to get more variation per column
    -- The id_hash is used as a z-offset to differentiate feature types
    local noise_val = noise.perlin2d(col * 0.5, z + id_hash * 0.01)
    -- Map noise from [-1, 1] to [0, 1]
    local normalized = (noise_val + 1) / 2
    return normalized < probability
end

-- Place a feature shape into the column
-- Note: This only modifies the current column, so multi-column features
-- will need to be handled differently (future enhancement)
local function place_feature(column_data, col, z, surface_row, feature, world_height)
    -- Select a random shape based on noise
    local shape_index = 1
    if #feature.shapes > 1 then
        local shape_noise = noise.perlin2d(col * 0.5, z * 0.5 + 1000)
        shape_index = math.floor((shape_noise + 1) / 2 * #feature.shapes) + 1
        shape_index = math.max(1, math.min(shape_index, #feature.shapes))
    end
    local shape = feature.shapes[shape_index]

    -- Shape is [row][col] where row 1 is top, and anchor is bottom-center
    local shape_height = #shape
    -- Calculate shape width by counting elements in first row (handles "air" placeholders)
    local shape_width = 0
    for _ in pairs(shape[1]) do
        shape_width = shape_width + 1
    end
    local anchor_col = math.ceil(shape_width / 2)

    -- Place blocks from the shape into the column
    -- Only place blocks that fall into this column (anchor_col)
    for row_idx = 1, shape_height do
        local shape_row = shape[row_idx]
        local block_name = shape_row[anchor_col]

        if block_name and block_name ~= "air" then
            local block_id = get_block_id_by_name(block_name)
            if block_id then
                -- Calculate world row position
                -- Anchor is at surface_row - 1 (first air block above surface)
                -- This places the feature base ON TOP of the surface block
                -- row_idx = shape_height is the anchor (bottom of shape)
                local offset_from_anchor = shape_height - row_idx
                local world_row = surface_row - 1 - offset_from_anchor

                -- Only place if within bounds and currently air
                -- This prevents overwriting existing solid blocks
                if world_row >= 0 and world_row < world_height then
                    if column_data[world_row] == BLOCKS.AIR then
                        column_data[world_row] = block_id
                    end
                end
            end
        end
    end
end

return function(column_data, col, z, base_height, world_height)
    local features = WorldRegistry:get_features()

    for _, feature in ipairs(features) do
        -- Check if feature can spawn on this layer
        if is_valid_layer(z, feature.layers) then
            -- Find surface block (first non-air from top)
            -- Note: This simple approach finds the topmost surface, which works well
            -- for initial terrain. In caves or overhangs, features would only spawn
            -- on the topmost surface, not inside caves.
            local surface_row = nil
            for row = 0, world_height - 1 do
                if column_data[row] ~= BLOCKS.AIR then
                    surface_row = row
                    break
                end
            end

            -- Check if we found a valid surface
            if surface_row and is_valid_surface(column_data[surface_row], feature.surface or {}) then
                -- Check spawn probability
                if should_spawn(col, z, feature) then
                    place_feature(column_data, col, z, surface_row, feature, world_height)
                end
            end
        end
    end
end
