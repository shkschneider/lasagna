local noise = require "core.noise"
local Registry = require "registries"
local BLOCKS = Registry.blocks()

-- Tree generation constants
local TREE_CLUSTER_THRESHOLD = 0.1  -- Higher = fewer tree clusters
local TREE_MIN_HEIGHT = 4
local TREE_MAX_HEIGHT = 6
local MIN_SPACE_BETWEEN_CLUSTERS = 30  -- Space between tree clusters
local CLUSTER_WIDTH = 10  -- How wide a cluster can span

-- Track cluster positions per layer
local cluster_data = {}

local function get_cluster_key(z)
    return tostring(z)
end

local function init_cluster_data(z)
    local key = get_cluster_key(z)
    if not cluster_data[key] then
        cluster_data[key] = {
            last_cluster_col = -MIN_SPACE_BETWEEN_CLUSTERS * 2,
            trees_in_cluster = 0,
            target_trees = 0,
            cluster_end_col = -1,
            pending_right_leaf = nil,  -- Stores trunk_top for next column's right leaf
        }
    end
    return cluster_data[key]
end

-- Get tree height for a given position
local function get_tree_height(world_col, z)
    local height_noise = noise.perlin2d(world_col * 0.3, z * 0.3)
    local normalized_noise = math.max(0, math.min(1, (height_noise + 1) / 2))
    local tree_height = TREE_MIN_HEIGHT + math.floor(normalized_noise * (TREE_MAX_HEIGHT - TREE_MIN_HEIGHT + 0.99))
    return math.max(TREE_MIN_HEIGHT, math.min(tree_height, TREE_MAX_HEIGHT))
end

-- Calculate trunk_top for a tree at given position
local function get_trunk_top(world_col, z, base_height)
    local tree_height = get_tree_height(world_col, z)
    local trunk_start = base_height - 1  -- One block above ground
    return trunk_start - tree_height + 1
end

-- Place a leaf at the given row
local function place_leaf(column_data, row)
    if row >= 0 and column_data[row] == BLOCKS.AIR then
        column_data[row] = BLOCKS.LEAVES
    end
end

local function should_start_cluster(world_col, z, data)
    -- Check spacing
    if (world_col - data.last_cluster_col) < MIN_SPACE_BETWEEN_CLUSTERS then
        return false
    end

    -- Use noise to determine if a cluster should start here
    local cluster_noise = noise.perlin2d(world_col * 0.05 + 1000, z * 0.05 + 1000)
    return cluster_noise > TREE_CLUSTER_THRESHOLD
end

local function determine_tree_count(world_col, z)
    -- Use noise to determine 1-3 trees in this cluster
    local count_noise = noise.perlin2d(world_col * 0.2 + 2000, z * 0.2 + 2000)
    -- Clamp noise to [-1, 1] range and map to [1, 3]
    local normalized_noise = math.max(0, math.min(1, (count_noise + 1) / 2))
    return math.max(1, math.min(3, 1 + math.floor(normalized_noise * 2.99)))
end

local function should_place_tree_in_cluster(world_col, z, data)
    -- Check if we're still within cluster bounds and haven't placed enough trees
    if data.trees_in_cluster >= data.target_trees then
        return false
    end
    if world_col > data.cluster_end_col then
        return false
    end

    -- Use noise to add some spacing variation within cluster
    local tree_noise = noise.perlin2d(world_col * 0.4 + 3000, z * 0.4 + 3000)
    return tree_noise > 0.3  -- Trees spaced within cluster
end

-- Check if a tree will be placed at the given column (for look-ahead)
local function will_have_tree_at(world_col, z, data_snapshot)
    local test_trees = data_snapshot.trees_in_cluster
    local test_target = data_snapshot.target_trees
    local test_last = data_snapshot.last_cluster_col
    local test_end = data_snapshot.cluster_end_col
    
    -- Check cluster state for the target column
    if test_trees >= test_target or world_col > test_end then
        -- Would need to start new cluster
        if (world_col - test_last) < MIN_SPACE_BETWEEN_CLUSTERS then
            return false
        end
        local cluster_noise = noise.perlin2d(world_col * 0.05 + 1000, z * 0.05 + 1000)
        if cluster_noise <= TREE_CLUSTER_THRESHOLD then
            return false
        end
    end
    
    -- Check if tree would be placed
    local tree_noise = noise.perlin2d(world_col * 0.4 + 3000, z * 0.4 + 3000)
    return tree_noise > 0.3
end

-- Try to place a left leaf if the next column will have a tree
local function try_place_left_leaf(column_data, world_col, z, base_height, data)
    local next_col = world_col + 1
    local snapshot = {
        trees_in_cluster = data.trees_in_cluster,
        target_trees = data.target_trees,
        last_cluster_col = data.last_cluster_col,
        cluster_end_col = data.cluster_end_col,
    }
    if will_have_tree_at(next_col, z, snapshot) then
        local trunk_top = get_trunk_top(next_col, z, base_height)
        place_leaf(column_data, trunk_top)
    end
end

-- Generate tree with triangle canopy
-- Tree structure (from top to bottom):
--   [ALA]  - air, leaves, air (row: trunk_top - 1)
--   [LTL]  - leaves, trunk(wood), leaves (row: trunk_top)
--   [ T ]  - trunk (rows below)
local function generate_tree_center(column_data, world_col, z, base_height)
    local tree_height = get_tree_height(world_col, z)
    
    -- Place wood trunk (going upward from surface)
    local trunk_start = base_height - 1  -- One block above ground
    local trunk_top = trunk_start - tree_height + 1
    
    for row = trunk_start, trunk_top, -1 do
        if row >= 0 and column_data[row] == BLOCKS.AIR then
            column_data[row] = BLOCKS.WOOD
        end
    end
    
    -- Place leaves at top of trunk (center column gets leaf above the top wood block)
    local leaf_top = trunk_top - 1
    if leaf_top >= 0 and column_data[leaf_top] == BLOCKS.AIR then
        column_data[leaf_top] = BLOCKS.LEAVES
    end
    
    return trunk_top
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

    local data = init_cluster_data(z)
    
    -- First, check if there's a pending right leaf from the previous tree
    if data.pending_right_leaf then
        place_leaf(column_data, data.pending_right_leaf)
        data.pending_right_leaf = nil
    end

    -- Check if we should start a new cluster
    if data.trees_in_cluster >= data.target_trees or world_col > data.cluster_end_col then
        if should_start_cluster(world_col, z, data) then
            data.last_cluster_col = world_col
            data.trees_in_cluster = 0
            data.target_trees = determine_tree_count(world_col, z)
            data.cluster_end_col = world_col + CLUSTER_WIDTH
        else
            -- No tree here, but check if NEXT column will have a tree (for left leaf)
            try_place_left_leaf(column_data, world_col, z, base_height, data)
            return
        end
    end

    -- Try to place a tree in the current cluster
    if should_place_tree_in_cluster(world_col, z, data) then
        local trunk_top = generate_tree_center(column_data, world_col, z, base_height)
        data.trees_in_cluster = data.trees_in_cluster + 1
        
        -- Schedule the right leaf for the next column
        data.pending_right_leaf = trunk_top
    else
        -- No tree here, but check if NEXT column will have a tree (for left leaf)
        try_place_left_leaf(column_data, world_col, z, base_height, data)
    end
end
