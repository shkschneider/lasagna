-- WorldGen library
-- Advanced ore vein, gem, and sand generation functions
--
-- This module implements the procedural generation rules for Lasagna's world,
-- including ore veins, gems, caves, and surface biomes like desert strips.
--
-- GENERATION ORDER (important for correct behavior):
-- 1. Basic terrain (stone, dirt, grass) - done in world.lua
-- 2. Cave generation (carves out air pockets) - creates exploration space
-- 3. Sand generation (surface biomes) - replaces surface blocks in desert areas
-- 4. Ore vein generation (replaces stone with ores) - adds resources
--
-- ORE GENERATION RULES:
-- - Ores spawn in VEINS (clusters), never as isolated blocks
-- - Each ore has:
--   * frequency: how often veins spawn (lower = rarer)
--   * vein_size: average blocks per vein
--   * vein_spread: radius of vein dispersion
--   * min_depth: depth below surface where ore starts appearing
--   * layers: which layers (-1, 0, 1) the ore can spawn in
--   * layer_frequency_multiplier: optional multiplier per layer
--
-- LAYER DISTRIBUTION:
-- - Layer 0 (surface/main): Basic ores (coal, copper, tin), some iron
-- - Layer -1 (back/deep): All ores, especially rich in iron, gold, rare ores
-- - Layer 1 (front): Minimal ores, more surface resources
--
-- ORE TYPES BY DEPTH:
-- - Shallow (10-20 blocks): Coal
-- - Medium (15-30 blocks): Copper, Tin (often mixed)
-- - Deep (25-40 blocks): Iron (richest in layer -1)
-- - Very Deep (35-50 blocks): Lead, Zinc
-- - Ultra Deep (40+ blocks): Gold
-- - Extreme Deep (50+ blocks): Cobalt (gem, only near caves)
--
-- GEM GENERATION:
-- - Cobalt: Ultra rare, only in layer -1, requires cave exposure
-- - Gems spawn as small clusters in or near cave walls
-- - Future: other gem types (emerald, ruby, etc.)
--
-- SAND GENERATION:
-- - Surface only (layer 0, 1)
-- - Forms desert "strips" or biomes using noise
-- - Replaces dirt/grass on surface, extends 3-6 blocks deep
-- - Rarely appears underground (except special cases)
--
-- CAVE GENERATION:
-- - Uses 3D Perlin noise to create winding tunnels
-- - Layer -1: Most caves (rougher, more dangerous)
-- - Layer 0: Moderate caves
-- - Layer 1: Fewer caves (safer, more building space)
-- - Caves start appearing 20+ blocks below surface
-- - Creates opportunities for gem discovery

local noise = require "lib.noise"

local worldgen = {}

-- Constants for noise scaling and offsets
worldgen.NOISE_CONSTANTS = {
    CAVE_Z_SCALE = 100,        -- Z-axis multiplier for cave noise
    ORE_Z_SCALE = 100,         -- Z-axis multiplier for ore noise
    BIOME_Z_SCALE = 10,        -- Z-axis multiplier for biome noise
    BIOME_Z_OFFSET = 1000,     -- Z-axis offset for biome noise
}

-- Ore configuration: defines spawn rules for each ore type
-- frequency: base chance of vein spawning (0-1)
-- vein_size: average number of blocks in a vein
-- vein_spread: how much the vein spreads (radius)
-- min_depth: minimum depth (row) where ore can spawn
-- max_depth: maximum depth (row) where ore can spawn (nil = no limit)
-- layers: which layers this ore can spawn in (-1, 0, 1)
worldgen.ORE_CONFIG = {
    COAL = {
        frequency = 0.008,
        vein_size = 8,
        vein_spread = 2.5,
        min_depth = 10,
        max_depth = nil,
        layers = {[-1] = true, [0] = true},
    },
    COPPER_ORE = {
        frequency = 0.006,
        vein_size = 6,
        vein_spread = 2.0,
        min_depth = 15,
        max_depth = nil,
        layers = {[-1] = true, [0] = true},
    },
    TIN_ORE = {
        frequency = 0.005,
        vein_size = 5,
        vein_spread = 1.8,
        min_depth = 15,
        max_depth = nil,
        layers = {[-1] = true, [0] = true},
    },
    IRON_ORE = {
        frequency = 0.007,
        vein_size = 7,
        vein_spread = 2.2,
        min_depth = 25,
        max_depth = nil,
        layers = {[-1] = true, [0] = true},
        -- Iron is more common in layer -1
        layer_frequency_multiplier = {[-1] = 1.5, [0] = 0.7},
    },
    GOLD_ORE = {
        frequency = 0.002,
        vein_size = 4,
        vein_spread = 1.5,
        min_depth = 40,
        max_depth = nil,
        layers = {[-1] = true},
    },
    LEAD_ORE = {
        frequency = 0.003,
        vein_size = 5,
        vein_spread = 1.6,
        min_depth = 35,
        max_depth = nil,
        layers = {[-1] = true},
    },
    ZINC_ORE = {
        frequency = 0.003,
        vein_size = 5,
        vein_spread = 1.6,
        min_depth = 35,
        max_depth = nil,
        layers = {[-1] = true},
    },
    COBALT_ORE = {
        frequency = 0.001,
        vein_size = 3,
        vein_spread = 1.2,
        min_depth = 50,
        max_depth = nil,
        layers = {[-1] = true},
        require_cave_exposure = true, -- Only spawn near air blocks
    },
}

-- Sand configuration for surface/biome generation
worldgen.SAND_CONFIG = {
    surface_frequency = 0.15, -- 15% chance of sand strips on surface
    strip_width = 20, -- Average width of sand strips
    depth_max = 8, -- Maximum depth of sand below surface
}

-- Cave configuration
worldgen.CAVE_CONFIG = {
    -- Layer -1 has more caves (rougher terrain)
    -- Lower threshold = fewer caves
    threshold = {[-1] = 0.55, [0] = 0.65, [1] = 0.75},
    min_depth = 20, -- Caves start appearing at this depth
}

-- Check if a position should be a cave
function worldgen.should_be_cave(z, col, row, base_height)
    local config = worldgen.CAVE_CONFIG
    
    -- No caves above ground or too shallow
    if row < base_height + config.min_depth then
        return false
    end
    
    -- Use 3D noise for cave generation (creates winding tunnels)
    local cave_noise = noise.perlin3d(col * 0.03, row * 0.03, z * worldgen.NOISE_CONSTANTS.CAVE_Z_SCALE)
    
    -- Layer-specific threshold (layer -1 has more caves)
    local threshold = config.threshold[z] or 0.65
    
    -- Caves are regions where noise is close to zero (creates tunnel-like structures)
    return math.abs(cave_noise) < (1 - threshold)
end

-- Generate an ore vein at a given position
-- Returns a table of {col, row} positions that should be replaced with ore
function worldgen.generate_vein(seed_col, seed_row, config, layer)
    local positions = {}
    local vein_size = config.vein_size
    local spread = config.vein_spread
    
    -- Use noise to make vein shapes irregular
    local noise_offset_x = seed_col * 0.1
    local noise_offset_y = seed_row * 0.1
    
    -- Generate vein blocks
    for i = 1, vein_size do
        -- Create roughly elliptical spread from seed position
        local angle = (i / vein_size) * math.pi * 2 + noise.perlin2d(seed_col * 0.05 + i, seed_row * 0.05) * math.pi
        local distance = spread * (0.5 + noise.perlin2d(seed_col * 0.1 + i * 10, seed_row * 0.1) * 0.5)
        
        local offset_col = math.floor(math.cos(angle) * distance + 0.5)
        local offset_row = math.floor(math.sin(angle) * distance + 0.5)
        
        table.insert(positions, {
            col = seed_col + offset_col,
            row = seed_row + offset_row
        })
    end
    
    return positions
end

-- Check if a position should have ore based on config and world state
function worldgen.should_spawn_ore(ore_name, config, z, col, row, base_height)
    -- Check layer
    if not config.layers[z] then
        return false
    end
    
    -- Check depth
    if row < (base_height + config.min_depth) then
        return false
    end
    
    if config.max_depth and row > (base_height + config.max_depth) then
        return false
    end
    
    -- Use noise for random but deterministic spawning
    local frequency = config.frequency
    
    -- Apply layer frequency multiplier if it exists
    if config.layer_frequency_multiplier and config.layer_frequency_multiplier[z] then
        frequency = frequency * config.layer_frequency_multiplier[z]
    end
    
    -- Use 3D noise for deterministic vein seed placement
    local noise_val = noise.perlin3d(col * 0.1, row * 0.1, z * worldgen.NOISE_CONSTANTS.ORE_Z_SCALE + ore_name:byte(1))
    
    return noise_val > (1 - frequency * 2)
end

-- Check if a block is exposed to air (for gems)
-- blocks_ref: table of block ID constants (needs AIR constant)
function worldgen.is_cave_exposed(layers, z, col, row, blocks_ref)
    -- Check adjacent blocks for air
    local directions = {
        {0, -1}, {0, 1}, {-1, 0}, {1, 0}
    }
    
    for _, dir in ipairs(directions) do
        local check_col = col + dir[1]
        local check_row = row + dir[2]
        
        if layers[z] and layers[z][check_col] and layers[z][check_col][check_row] then
            local block_id = layers[z][check_col][check_row]
            -- Check if it's air
            if block_id == blocks_ref.AIR then
                return true
            end
        end
    end
    
    return false
end

-- Generate sand for surface biomes
function worldgen.should_place_sand(col, row, base_height, z)
    -- Only place sand on or near surface in layer 0
    if z ~= 0 and z ~= 1 then
        return false
    end
    
    -- Must be at or slightly below surface
    local depth_below_surface = row - base_height
    if depth_below_surface < 0 or depth_below_surface > worldgen.SAND_CONFIG.depth_max then
        return false
    end
    
    -- Use noise to create desert strips
    local biome_noise = noise.perlin2d(col * 0.02, z * worldgen.NOISE_CONSTANTS.BIOME_Z_SCALE + worldgen.NOISE_CONSTANTS.BIOME_Z_OFFSET)
    
    -- If in a desert biome zone
    if biome_noise > 0.3 then
        -- Vary depth based on another noise layer
        local depth_noise = noise.perlin2d(col * 0.1, row * 0.1)
        local max_sand_depth = 3 + math.floor(depth_noise * 3)
        
        return depth_below_surface <= max_sand_depth
    end
    
    return false
end

-- Apply ore generation to a column
-- This function should be called after basic terrain is generated
-- blocks_ref: table of block ID constants
-- layers: the world layers data structure
-- z: the layer being generated
-- col: the column being generated
-- base_height: the surface height for this column
function worldgen.apply_ore_generation(blocks_ref, layers, z, col, base_height, world_height)
    local ores_to_check = {
        {name = "COAL", block_id = blocks_ref.COAL},
        {name = "COPPER_ORE", block_id = blocks_ref.COPPER_ORE},
        {name = "TIN_ORE", block_id = blocks_ref.TIN_ORE},
        {name = "IRON_ORE", block_id = blocks_ref.IRON_ORE},
        {name = "GOLD_ORE", block_id = blocks_ref.GOLD_ORE},
        {name = "LEAD_ORE", block_id = blocks_ref.LEAD_ORE},
        {name = "ZINC_ORE", block_id = blocks_ref.ZINC_ORE},
        {name = "COBALT_ORE", block_id = blocks_ref.COBALT_ORE},
    }
    
    -- Check each row in the column for potential ore veins
    for row = base_height, world_height - 1 do
        -- Skip if not stone (only replace stone with ores)
        if layers[z][col][row] ~= blocks_ref.STONE then
            goto continue
        end
        
        -- Check each ore type
        for _, ore_info in ipairs(ores_to_check) do
            local config = worldgen.ORE_CONFIG[ore_info.name]
            
            if worldgen.should_spawn_ore(ore_info.name, config, z, col, row, base_height) then
                -- Generate a vein starting at this position
                local vein_positions = worldgen.generate_vein(col, row, config, z)
                
                -- Place ore blocks
                for _, pos in ipairs(vein_positions) do
                    -- Check bounds
                    if pos.row >= base_height and pos.row < world_height then
                        -- Initialize column if needed
                        if not layers[z][pos.col] then
                            layers[z][pos.col] = {}
                        end
                        
                        -- Only replace stone blocks
                        if layers[z][pos.col][pos.row] == blocks_ref.STONE then
                            -- For gems, check cave exposure requirement
                            if config.require_cave_exposure then
                                if worldgen.is_cave_exposed(layers, z, pos.col, pos.row, blocks_ref) then
                                    layers[z][pos.col][pos.row] = ore_info.block_id
                                end
                            else
                                layers[z][pos.col][pos.row] = ore_info.block_id
                            end
                        end
                    end
                end
                
                -- Don't check other ores for this position (only one ore type per seed point)
                break
            end
        end
        
        ::continue::
    end
end

-- Apply sand generation to a column
function worldgen.apply_sand_generation(blocks_ref, layers, z, col, base_height, world_height)
    -- Check each row for sand placement
    for row = base_height, math.min(base_height + worldgen.SAND_CONFIG.depth_max, world_height - 1) do
        if worldgen.should_place_sand(col, row, base_height, z) then
            -- Replace dirt or grass with sand
            local current_block = layers[z][col][row]
            if current_block == blocks_ref.DIRT or current_block == blocks_ref.GRASS or current_block == blocks_ref.STONE then
                layers[z][col][row] = blocks_ref.SAND
            end
        end
    end
end

-- Apply cave generation to a column
-- Should be called before ore generation so ores can spawn near caves
function worldgen.apply_cave_generation(blocks_ref, layers, z, col, base_height, world_height)
    -- Check each row for cave placement
    for row = base_height, world_height - 1 do
        -- Only carve caves in solid blocks
        local current_block = layers[z][col][row]
        if current_block ~= blocks_ref.AIR then
            if worldgen.should_be_cave(z, col, row, base_height) then
                layers[z][col][row] = blocks_ref.AIR
            end
        end
    end
end

return worldgen
