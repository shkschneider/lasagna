-- World generation and block storage
-- Three layers: -1 (back), 0 (main), 1 (front)
-- Lazy column generation with seeded Perlin noise

local blocks = require("blocks")
local noise = require("lib.noise")

local world = {}

-- Block size in pixels
world.BLOCK_SIZE = 32

-- World dimensions (in blocks)
world.WIDTH = 256
world.HEIGHT = 128

-- Terrain generation constants
local BASE_HEIGHT = 0.6  -- Base height as fraction of world height
local BASE_FREQUENCY = 0.02  -- Controls horizontal terrain stretching
local BASE_AMPLITUDE = 15    -- Controls vertical height variation

-- Dirt layer constants
local DIRT_MIN_DEPTH = 5
local DIRT_MAX_DEPTH = 15
local DIRT_NOISE_FREQUENCY = 0.05

-- Cave generation constants
local CAVE_MIN_DEPTH = 10
local CAVE_THRESHOLD_LAYER_BACK = 0.6  -- More caves in back layer
local CAVE_THRESHOLD_LAYER_MAIN = 0.7  -- Fewer caves in main layer
local CAVE_NOISE_FREQUENCY = 0.05
local CAVE_NOISE_OCTAVES = 3
local CAVE_NOISE_PERSISTENCE = 0.5
local CAVE_NOISE_LACUNARITY = 2.0

-- Terrain noise constants
local TERRAIN_NOISE_OCTAVES = 4
local TERRAIN_NOISE_PERSISTENCE = 0.5
local TERRAIN_NOISE_LACUNARITY = 2.0

-- Ore generation constants
-- Blob generation (for coal, surface resources)
local COAL_BLOB_CHANCE = 0.02  -- Chance per valid position
local COAL_BLOB_RADIUS_MIN = 2
local COAL_BLOB_RADIUS_MAX = 4

local SAND_BLOB_CHANCE = 0.03  -- Chance per valid position on surface
local SAND_BLOB_RADIUS_MIN = 3
local SAND_BLOB_RADIUS_MAX = 6

-- Vein generation (for metals, ores)
local COPPER_VEIN_CHANCE = 0.015
local COPPER_VEIN_LENGTH_MIN = 8
local COPPER_VEIN_LENGTH_MAX = 15
local COPPER_VEIN_BRANCH_PROB = 0.2

local TIN_VEIN_CHANCE = 0.015
local TIN_VEIN_LENGTH_MIN = 8
local TIN_VEIN_LENGTH_MAX = 15
local TIN_VEIN_BRANCH_PROB = 0.2

local IRON_VEIN_CHANCE = 0.01
local IRON_VEIN_LENGTH_MIN = 10
local IRON_VEIN_LENGTH_MAX = 20
local IRON_VEIN_BRANCH_PROB = 0.25

local LEAD_VEIN_CHANCE = 0.01
local LEAD_VEIN_LENGTH_MIN = 10
local LEAD_VEIN_LENGTH_MAX = 18
local LEAD_VEIN_BRANCH_PROB = 0.2

local ZINC_VEIN_CHANCE = 0.01
local ZINC_VEIN_LENGTH_MIN = 10
local ZINC_VEIN_LENGTH_MAX = 18
local ZINC_VEIN_BRANCH_PROB = 0.2

local COBALT_VEIN_CHANCE = 0.005
local COBALT_VEIN_LENGTH_MIN = 12
local COBALT_VEIN_LENGTH_MAX = 25
local COBALT_VEIN_BRANCH_PROB = 0.3

-- LCG constants for random number generator
local LCG_MULTIPLIER = 1103515245
local LCG_INCREMENT = 12345
local LCG_MODULUS = 2147483648

-- Ore spawn noise thresholds (higher = rarer)
local COAL_NOISE_THRESHOLD = 0.85
local COPPER_NOISE_THRESHOLD = 0.88
local TIN_NOISE_THRESHOLD = 0.88
local IRON_NOISE_THRESHOLD = 0.90
local LEAD_NOISE_THRESHOLD = 0.90
local ZINC_NOISE_THRESHOLD = 0.90
local COBALT_NOISE_THRESHOLD = 0.93

function world.new(seed)
    local w = {
        seed = seed or os.time(),
        layers = {
            [-1] = {}, -- back layer
            [0] = {},  -- main layer
            [1] = {},  -- front layer
        },
        generated_columns = {},
        ore_veins_placed = {}, -- Track which ore veins have been generated
    }
    
    -- Initialize noise with seed
    noise.seed(w.seed)
    
    return w
end

-- Helper: Create a seeded random number generator for consistent vein/blob placement
local function make_random(seed)
    local state = seed
    return function(min_val, max_val)
        -- Simple LCG (Linear Congruential Generator)
        state = (state * LCG_MULTIPLIER + LCG_INCREMENT) % LCG_MODULUS
        if min_val and max_val then
            return min_val + (state % (max_val - min_val + 1))
        else
            return state / LCG_MODULUS
        end
    end
end

-- Blobby/Roundish cluster placement (for coal, surface materials)
-- can_replace_surface: If true, can replace dirt/grass (for surface resources like sand)
--                       If false, only replaces stone (for underground resources like coal)
local function place_blob(w, layer, x0, y0, radius, block_type, can_replace_surface)
    for dx = -radius, radius do
        for dy = -radius, radius do
            -- Circular shape with slight noise variation
            local dist_sq = dx * dx + dy * dy
            local actual_radius = radius + noise.perlin2d(x0 + dx * 0.3, y0 + dy * 0.3) * 0.5
            
            if dist_sq <= actual_radius * actual_radius then
                local col = x0 + dx
                local row = y0 + dy
                
                -- Check bounds
                if col >= 0 and col < world.WIDTH and row >= 0 and row < world.HEIGHT then
                    if w.layers[layer] and w.layers[layer][col] then
                        local current_block = w.layers[layer][col][row]
                        -- Replace stone for underground resources
                        -- Or replace dirt/grass for surface resources if allowed
                        if current_block == blocks.STONE or
                           (can_replace_surface and (current_block == blocks.DIRT or current_block == blocks.GRASS)) then
                            w.layers[layer][col][row] = block_type
                        end
                    end
                end
            end
        end
    end
end

-- Vein/Tentacle spread (for ores, metals using random walk)
local function place_vein(w, layer, x0, y0, length, block_type, branch_prob, random, bias_down)
    if bias_down == nil then bias_down = true end
    local x, y = x0, y0
    
    for i = 0, length do
        -- Place ore at current position (only replace stone)
        if x >= 0 and x < world.WIDTH and y >= 0 and y < world.HEIGHT then
            if w.layers[layer] and w.layers[layer][x] and 
               w.layers[layer][x][y] == blocks.STONE then
                w.layers[layer][x][y] = block_type
            end
        end
        
        -- Random walk step
        local dx = random(-1, 1)
        local dy
        if bias_down then
            -- Bias towards going down or horizontal
            local dir = random(0, 2)
            if dir == 0 then dy = 0      -- Horizontal
            elseif dir == 1 then dy = 1  -- Down
            else dy = -1                 -- Up (less common)
            end
        else
            dy = random(-1, 1)
        end
        
        x = x + dx
        y = y + dy
        
        -- Occasional branching
        if random() < branch_prob and length > 4 then
            local branch_length = math.floor(length / 2)
            place_vein(w, layer, x, y, branch_length, block_type, branch_prob * 0.7, random, bias_down)
        end
    end
end

-- Generate a single column across all layers
function world.generate_column(w, col)
    if w.generated_columns[col] then
        return
    end
    
    -- Base terrain parameters
    local base_height = world.HEIGHT * BASE_HEIGHT
    
    -- Generate height for each layer using Perlin noise with different characteristics
    for layer = -1, 1 do
        if not w.layers[layer][col] then
            w.layers[layer][col] = {}
        end
        
        -- Layer-specific adjustments
        local layer_frequency = BASE_FREQUENCY
        local layer_amplitude = BASE_AMPLITUDE
        local layer_base = base_height
        
        if layer == 1 then
            -- Layer 1: slightly higher, smoother (front layer)
            layer_frequency = BASE_FREQUENCY * 0.8  -- Smoother
            layer_amplitude = BASE_AMPLITUDE * 0.7   -- Less variation
            layer_base = base_height + 3              -- Slightly higher (lower on screen)
        elseif layer == -1 then
            -- Layer -1: slightly lower, rougher (back layer for caves/mining)
            layer_frequency = BASE_FREQUENCY * 1.3   -- Rougher
            layer_amplitude = BASE_AMPLITUDE * 1.2   -- More variation
            layer_base = base_height - 5              -- Slightly lower (higher on screen)
        end
        
        -- Calculate surface height using Perlin noise
        local height_noise = noise.octave_perlin2d(col * layer_frequency, layer * 10, 
            TERRAIN_NOISE_OCTAVES, TERRAIN_NOISE_PERSISTENCE, TERRAIN_NOISE_LACUNARITY)
        local surface_y = math.floor(layer_base + height_noise * layer_amplitude)
        
        -- Determine dirt layer depth (5-15 blocks)
        local dirt_depth_noise = noise.perlin1d(col * DIRT_NOISE_FREQUENCY + layer * 100)
        local dirt_depth = math.floor(DIRT_MIN_DEPTH + (dirt_depth_noise * 0.5 + 0.5) * (DIRT_MAX_DEPTH - DIRT_MIN_DEPTH))
        
        -- Generate column from top to bottom
        for row = 0, world.HEIGHT - 1 do
            local depth = row - surface_y
            
            if depth < 0 then
                -- Air above surface
                w.layers[layer][col][row] = blocks.AIR
            elseif depth < dirt_depth then
                -- Dirt layer (5-15 blocks deep)
                w.layers[layer][col][row] = blocks.DIRT
            else
                -- Underground: stone with ores
                local underground_noise = noise.perlin3d(col * 0.1, row * 0.1, layer * 50)
                
                -- Default to stone
                w.layers[layer][col][row] = blocks.STONE
                
                -- Add caves in layer -1 and 0 (more in -1)
                local cave_threshold = (layer == -1) and CAVE_THRESHOLD_LAYER_BACK or CAVE_THRESHOLD_LAYER_MAIN
                local cave_noise = noise.octave_perlin2d(col * CAVE_NOISE_FREQUENCY, row * CAVE_NOISE_FREQUENCY,
                    CAVE_NOISE_OCTAVES, CAVE_NOISE_PERSISTENCE, CAVE_NOISE_LACUNARITY)
                if depth > CAVE_MIN_DEPTH and cave_noise > cave_threshold then
                    w.layers[layer][col][row] = blocks.AIR
                end
            end
        end
        
        -- Ore vein/blob generation pass
        -- Use noise to determine spawn points for veins/blobs
        -- Random generator seeded per column for consistent vein placement within the column
        local random = make_random(w.seed + col + layer * 10000)
        
        for row = 0, world.HEIGHT - 1 do
            if w.layers[layer][col][row] == blocks.STONE then
                local depth = row - surface_y
                
                -- Coal blobs: moderate depth, all layers
                if depth > 10 and depth < 60 then
                    local coal_check = noise.perlin2d(col * 0.1, row * 0.1)
                    if coal_check > COAL_NOISE_THRESHOLD and random() < COAL_BLOB_CHANCE then
                        local vein_key = string.format("coal_%d_%d_%d", layer, col, row)
                        if not w.ore_veins_placed[vein_key] then
                            w.ore_veins_placed[vein_key] = true
                            local radius = random(COAL_BLOB_RADIUS_MIN, COAL_BLOB_RADIUS_MAX)
                            place_blob(w, layer, col, row, radius, blocks.COAL, false)
                        end
                    end
                end
                
                -- Copper veins: deeper, layers -1 and 0
                if depth > 15 and depth < 80 and (layer == -1 or layer == 0) then
                    local copper_check = noise.perlin2d(col * 0.08 + 100, row * 0.08)
                    if copper_check > COPPER_NOISE_THRESHOLD and random() < COPPER_VEIN_CHANCE then
                        local vein_key = string.format("copper_%d_%d_%d", layer, col, row)
                        if not w.ore_veins_placed[vein_key] then
                            w.ore_veins_placed[vein_key] = true
                            local length = random(COPPER_VEIN_LENGTH_MIN, COPPER_VEIN_LENGTH_MAX)
                            place_vein(w, layer, col, row, length, blocks.COPPER_ORE, 
                                COPPER_VEIN_BRANCH_PROB, random, true)
                        end
                    end
                end
                
                -- Tin veins: similar to copper, layers -1 and 0
                if depth > 15 and depth < 80 and (layer == -1 or layer == 0) then
                    local tin_check = noise.perlin2d(col * 0.08 + 200, row * 0.08 + 50)
                    if tin_check > TIN_NOISE_THRESHOLD and random() < TIN_VEIN_CHANCE then
                        local vein_key = string.format("tin_%d_%d_%d", layer, col, row)
                        if not w.ore_veins_placed[vein_key] then
                            w.ore_veins_placed[vein_key] = true
                            local length = random(TIN_VEIN_LENGTH_MIN, TIN_VEIN_LENGTH_MAX)
                            place_vein(w, layer, col, row, length, blocks.TIN_ORE, 
                                TIN_VEIN_BRANCH_PROB, random, true)
                        end
                    end
                end
                
                -- Iron veins: very deep, primarily layer -1
                if depth > 25 and layer == -1 then
                    local iron_check = noise.perlin2d(col * 0.06 + 300, row * 0.06)
                    if iron_check > IRON_NOISE_THRESHOLD and random() < IRON_VEIN_CHANCE then
                        local vein_key = string.format("iron_%d_%d_%d", layer, col, row)
                        if not w.ore_veins_placed[vein_key] then
                            w.ore_veins_placed[vein_key] = true
                            local length = random(IRON_VEIN_LENGTH_MIN, IRON_VEIN_LENGTH_MAX)
                            place_vein(w, layer, col, row, length, blocks.IRON_ORE, 
                                IRON_VEIN_BRANCH_PROB, random, true)
                        end
                    end
                end
                
                -- Lead veins: deep, layers -1 and 0
                if depth > 20 and layer == -1 then
                    local lead_check = noise.perlin2d(col * 0.06 + 400, row * 0.06 + 100)
                    if lead_check > LEAD_NOISE_THRESHOLD and random() < LEAD_VEIN_CHANCE then
                        local vein_key = string.format("lead_%d_%d_%d", layer, col, row)
                        if not w.ore_veins_placed[vein_key] then
                            w.ore_veins_placed[vein_key] = true
                            local length = random(LEAD_VEIN_LENGTH_MIN, LEAD_VEIN_LENGTH_MAX)
                            place_vein(w, layer, col, row, length, blocks.LEAD_ORE, 
                                LEAD_VEIN_BRANCH_PROB, random, true)
                        end
                    end
                end
                
                -- Zinc veins: deep, layers -1 and 0
                if depth > 20 and layer == -1 then
                    local zinc_check = noise.perlin2d(col * 0.06 + 500, row * 0.06 + 150)
                    if zinc_check > ZINC_NOISE_THRESHOLD and random() < ZINC_VEIN_CHANCE then
                        local vein_key = string.format("zinc_%d_%d_%d", layer, col, row)
                        if not w.ore_veins_placed[vein_key] then
                            w.ore_veins_placed[vein_key] = true
                            local length = random(ZINC_VEIN_LENGTH_MIN, ZINC_VEIN_LENGTH_MAX)
                            place_vein(w, layer, col, row, length, blocks.ZINC_ORE, 
                                ZINC_VEIN_BRANCH_PROB, random, true)
                        end
                    end
                end
                
                -- Cobalt veins: very rare, very deep, only layer -1
                if depth > 40 and layer == -1 then
                    local cobalt_check = noise.perlin2d(col * 0.05 + 600, row * 0.05 + 200)
                    if cobalt_check > COBALT_NOISE_THRESHOLD and random() < COBALT_VEIN_CHANCE then
                        local vein_key = string.format("cobalt_%d_%d_%d", layer, col, row)
                        if not w.ore_veins_placed[vein_key] then
                            w.ore_veins_placed[vein_key] = true
                            local length = random(COBALT_VEIN_LENGTH_MIN, COBALT_VEIN_LENGTH_MAX)
                            place_vein(w, layer, col, row, length, blocks.COBALT_ORE, 
                                COBALT_VEIN_BRANCH_PROB, random, true)
                        end
                    end
                end
            end
        end
        
        -- Surface resource generation (layer 1 only)
        if layer == 1 then
            for row = 0, world.HEIGHT - 1 do
                if w.layers[layer][col][row] == blocks.DIRT or w.layers[layer][col][row] == blocks.GRASS then
                    local depth = row - surface_y
                    
                    -- Sand blobs on surface (shallow depth)
                    if depth >= 0 and depth < 5 then
                        local sand_check = noise.perlin2d(col * 0.12 + 700, row * 0.12)
                        if sand_check > 0.8 and random() < SAND_BLOB_CHANCE then
                            local blob_key = string.format("sand_%d_%d_%d", layer, col, row)
                            if not w.ore_veins_placed[blob_key] then
                                w.ore_veins_placed[blob_key] = true
                                local radius = random(SAND_BLOB_RADIUS_MIN, SAND_BLOB_RADIUS_MAX)
                                place_blob(w, layer, col, row, radius, blocks.SAND, true)
                            end
                        end
                    end
                end
            end
        end
        
        -- Grass conversion pass: convert dirt exposed to air into grass
        for row = 0, world.HEIGHT - 1 do
            if w.layers[layer][col][row] == blocks.DIRT then
                -- Check if this dirt should become grass (exposed to air or at world top)
                if row == 0 then
                    -- At top of world, convert to grass (exposed to sky)
                    w.layers[layer][col][row] = blocks.GRASS
                else
                    local above = w.layers[layer][col][row - 1]
                    if above == blocks.AIR then
                        w.layers[layer][col][row] = blocks.GRASS
                    end
                end
            end
        end
    end
    
    w.generated_columns[col] = true
end

-- Get block at position
function world.get_block(w, layer, col, row)
    if col < 0 or col >= world.WIDTH or row < 0 or row >= world.HEIGHT then
        return blocks.AIR
    end
    
    world.generate_column(w, col)
    
    if not w.layers[layer] or not w.layers[layer][col] then
        return blocks.AIR
    end
    
    return w.layers[layer][col][row] or blocks.AIR
end

-- Get block prototype at position
function world.get_block_proto(w, layer, col, row)
    local block_id = world.get_block(w, layer, col, row)
    return blocks.get_proto(block_id)
end

-- Set block at position
function world.set_block(w, layer, col, row, block_id)
    if col < 0 or col >= world.WIDTH or row < 0 or row >= world.HEIGHT then
        return false
    end
    
    world.generate_column(w, col)
    
    if not w.layers[layer] then
        w.layers[layer] = {}
    end
    if not w.layers[layer][col] then
        w.layers[layer][col] = {}
    end
    
    w.layers[layer][col][row] = block_id
    return true
end

-- Convert world position to block coordinates
function world.world_to_block(wx, wy)
    return math.floor(wx / world.BLOCK_SIZE), math.floor(wy / world.BLOCK_SIZE)
end

-- Convert block coordinates to world position
function world.block_to_world(col, row)
    return col * world.BLOCK_SIZE, row * world.BLOCK_SIZE
end

-- Find spawn position on ground (first solid block from top)
function world.find_spawn_position(w, start_col, layer)
    layer = layer or 0
    start_col = start_col or math.floor(world.WIDTH / 2)
    
    -- Generate the column if not already generated
    world.generate_column(w, start_col)
    
    -- Search from top to bottom for first solid block
    for row = 0, world.HEIGHT - 1 do
        local block_id = world.get_block(w, layer, start_col, row)
        local proto = blocks.get_proto(block_id)
        
        if proto and proto.solid then
            -- Found ground, spawn just above it
            local wx, wy = world.block_to_world(start_col, row)
            return wx, wy - world.BLOCK_SIZE / 2, layer
        end
    end
    
    -- Fallback if no ground found (shouldn't happen)
    local wx, wy = world.block_to_world(start_col, world.HEIGHT / 2)
    return wx, wy, layer
end

return world
