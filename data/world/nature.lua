local noise = require "core.noise"
local Registry = require "registries"
local BLOCKS = Registry.blocks()

-- Tree generation constants
local TREE_CLUSTER_THRESHOLD = 0.1  -- Higher = fewer tree clusters
local TREE_MIN_HEIGHT = 4
local TREE_MAX_HEIGHT = 6
local MIN_SPACE_BETWEEN_CLUSTERS = 30  -- Space between tree clusters
local CLUSTER_WIDTH = 10  -- How wide a cluster can span

-- Track pending tree data per layer for the "paste tree" approach
local pending_trees = {}

local function get_layer_key(z)
    return tostring(z)
end

local function init_pending_trees(z)
    local key = get_layer_key(z)
    if not pending_trees[key] then
        pending_trees[key] = {
            last_cluster_col = -MIN_SPACE_BETWEEN_CLUSTERS * 2,
            trees_in_cluster = 0,
            target_trees = 0,
            cluster_end_col = -1,
            trees = {},  -- List of {center_col, base_height, trunk_height} to paste
        }
    end
    return pending_trees[key]
end

-- Get tree height for a given position
local function get_tree_height(world_col, z)
    local height_noise = noise.perlin2d(world_col * 0.3, z * 0.3)
    local normalized_noise = math.max(0, math.min(1, (height_noise + 1) / 2))
    -- Double height for layer -1
    local min_height = z == -1 and TREE_MIN_HEIGHT * 2 or TREE_MIN_HEIGHT
    local max_height = z == -1 and TREE_MAX_HEIGHT * 2 or TREE_MAX_HEIGHT
    local tree_height = min_height + math.floor(normalized_noise * (max_height - min_height + 0.99))
    return math.max(min_height, math.min(tree_height, max_height))
end

local function should_start_cluster(world_col, z, data)
    if (world_col - data.last_cluster_col) < MIN_SPACE_BETWEEN_CLUSTERS then
        return false
    end
    local cluster_noise = noise.perlin2d(world_col * 0.05 + 1000, z * 0.05 + 1000)
    return cluster_noise > TREE_CLUSTER_THRESHOLD
end

local function determine_tree_count(world_col, z)
    local count_noise = noise.perlin2d(world_col * 0.2 + 2000, z * 0.2 + 2000)
    local normalized_noise = math.max(0, math.min(1, (count_noise + 1) / 2))
    return math.max(1, math.min(3, 1 + math.floor(normalized_noise * 2.99)))
end

local function should_place_tree_in_cluster(world_col, z, data)
    if data.trees_in_cluster >= data.target_trees then
        return false
    end
    if world_col > data.cluster_end_col then
        return false
    end
    local tree_noise = noise.perlin2d(world_col * 0.4 + 3000, z * 0.4 + 3000)
    return tree_noise > 0.3
end

-- Place a block at the given row if it's air
local function place_block(column_data, row, block_id)
    if row >= 0 and column_data[row] == BLOCKS.AIR then
        column_data[row] = block_id
    end
end

-- Paste a small tree (layer 0): 1-wide trunk, small triangle canopy
-- Structure (from top to bottom):
--   [ALA]  - air, leaves, air
--   [LTL]  - leaves, trunk, leaves
--   [ T ]  - trunk
--   [ T ]  - trunk
local function paste_small_tree(column_data, world_col, tree, current_col)
    local center_col = tree.center_col
    local base_height = tree.base_height
    local trunk_height = tree.trunk_height
    local trunk_start = base_height - 1
    local trunk_top = trunk_start - trunk_height + 1
    local offset = current_col - center_col
    
    if offset == 0 then
        -- Center column: trunk + top leaf
        for row = trunk_start, trunk_top, -1 do
            place_block(column_data, row, BLOCKS.WOOD)
        end
        place_block(column_data, trunk_top - 1, BLOCKS.LEAVES)
    elseif offset == -1 or offset == 1 then
        -- Left/right columns: leaf at trunk_top level
        place_block(column_data, trunk_top, BLOCKS.LEAVES)
    end
end

-- Paste a big tree (layer -1): 2-wide trunk, larger triangle canopy
-- Structure (from top to bottom, 4 columns wide):
--   [ALLA]   - air, leaf, leaf, air (leaves above trunk columns)
--   [LTTL]   - leaf, trunk, trunk, leaf
--   [ TT ]   - trunk, trunk
--   [ TT ]   - trunk, trunk
local function paste_big_tree(column_data, world_col, tree, current_col)
    local center_col = tree.center_col  -- This is the LEFT trunk column
    local base_height = tree.base_height
    local trunk_height = tree.trunk_height
    local trunk_start = base_height - 1
    local trunk_top = trunk_start - trunk_height + 1
    local offset = current_col - center_col
    
    if offset == 0 or offset == 1 then
        -- Trunk columns (2 wide): trunk + top leaves
        for row = trunk_start, trunk_top, -1 do
            place_block(column_data, row, BLOCKS.WOOD)
        end
        place_block(column_data, trunk_top - 1, BLOCKS.LEAVES)
    elseif offset == -1 or offset == 2 then
        -- Outer leaf columns: leaf at trunk_top level
        place_block(column_data, trunk_top, BLOCKS.LEAVES)
    end
end

-- Check if this column is affected by any pending tree and paste the relevant parts
local function paste_trees_for_column(column_data, world_col, z, data)
    local paste_fn = z == -1 and paste_big_tree or paste_small_tree
    local tree_width = z == -1 and 4 or 3  -- Big trees are 4 wide, small are 3 wide
    
    -- Check each pending tree
    local remaining_trees = {}
    for _, tree in ipairs(data.trees) do
        local center_col = tree.center_col
        local min_col = center_col - 1
        local max_col = z == -1 and (center_col + 2) or (center_col + 1)
        
        if world_col >= min_col and world_col <= max_col then
            paste_fn(column_data, world_col, tree, world_col)
        end
        
        -- Keep trees that might still affect future columns
        if world_col < max_col then
            table.insert(remaining_trees, tree)
        end
    end
    data.trees = remaining_trees
end

return function(column_data, world_col, z, base_height, world_height)
    -- Only spawn trees on layers -1 and 0 (not on layer 1)
    if z == 1 then
        return
    end
    
    -- Only spawn trees on grass
    if not (base_height > 0 and base_height < world_height and column_data[base_height] == BLOCKS.GRASS) then
        return
    end

    local data = init_pending_trees(z)
    
    -- First, paste any pending trees that affect this column
    paste_trees_for_column(column_data, world_col, z, data)

    -- Check if we should start a new cluster
    if data.trees_in_cluster >= data.target_trees or world_col > data.cluster_end_col then
        if should_start_cluster(world_col, z, data) then
            data.last_cluster_col = world_col
            data.trees_in_cluster = 0
            data.target_trees = determine_tree_count(world_col, z)
            data.cluster_end_col = world_col + CLUSTER_WIDTH
        else
            return
        end
    end

    -- Try to place a tree in the current cluster
    if should_place_tree_in_cluster(world_col, z, data) then
        local trunk_height = get_tree_height(world_col, z)
        
        -- Register the tree for pasting
        table.insert(data.trees, {
            center_col = world_col,
            base_height = base_height,
            trunk_height = trunk_height,
        })
        data.trees_in_cluster = data.trees_in_cluster + 1
        
        -- Paste the current column immediately
        local paste_fn = z == -1 and paste_big_tree or paste_small_tree
        paste_fn(column_data, world_col, data.trees[#data.trees], world_col)
    end
end
