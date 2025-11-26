local noise = require "core.noise"
local Registry = require "registries"
local BLOCKS = Registry.blocks()

-- Tree generation constants
local TREE_CLUSTER_THRESHOLD = 0.6  -- Higher = fewer tree clusters
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
        }
    end
    return cluster_data[key]
end

local function generate_tree(column_data, world_col, z, base_height)
    -- Determine tree height using noise
    local height_noise = noise.perlin2d(world_col * 0.3, z * 0.3)
    local tree_height = TREE_MIN_HEIGHT + math.floor((height_noise + 1) / 2 * (TREE_MAX_HEIGHT - TREE_MIN_HEIGHT))
    tree_height = math.min(tree_height, TREE_MAX_HEIGHT)
    
    -- Place wood trunk (going upward from surface)
    local trunk_start = base_height - 1  -- One block above ground
    for row = trunk_start, trunk_start - tree_height + 1, -1 do
        if row >= 0 and column_data[row] == BLOCKS.AIR then
            column_data[row] = BLOCKS.WOOD
        end
    end
    
    -- Place leaves at top of trunk (simple 2D canopy)
    local canopy_center = trunk_start - tree_height + 1
    -- Place leaves above and around the trunk top
    for row = canopy_center - 2, canopy_center + 1 do
        if row >= 0 and column_data[row] == BLOCKS.AIR then
            column_data[row] = BLOCKS.LEAVES
        end
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
    -- Map noise from [-1, 1] to [1, 3]
    return math.min(3, 1 + math.floor((count_noise + 1) / 2 * 3))
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

return function(column_data, world_col, z, base_height, world_height)
    -- Only spawn trees on grass
    if not (base_height > 0 and base_height < world_height and column_data[base_height] == BLOCKS.GRASS) then
        return
    end
    
    local data = init_cluster_data(z)
    
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
        generate_tree(column_data, world_col, z, base_height)
        data.trees_in_cluster = data.trees_in_cluster + 1
    end
end
