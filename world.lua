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

function world.new(seed)
    local w = {
        seed = seed or os.time(),
        layers = {
            [-1] = {}, -- back layer
            [0] = {},  -- main layer
            [1] = {},  -- front layer
        },
        generated_columns = {},
    }
    
    -- Initialize noise with seed
    noise.seed(w.seed)
    
    return w
end

-- Generate a single column across all layers
function world.generate_column(w, col)
    if w.generated_columns[col] then
        return
    end
    
    -- Base terrain parameters
    local base_height = world.HEIGHT * 0.6
    local frequency = 0.02 -- Controls how "stretched" the terrain is
    local amplitude = 15    -- Controls height variation
    
    -- Generate height for each layer using Perlin noise with different characteristics
    for layer = -1, 1 do
        if not w.layers[layer][col] then
            w.layers[layer][col] = {}
        end
        
        -- Layer-specific adjustments
        local layer_frequency = frequency
        local layer_amplitude = amplitude
        local layer_base = base_height
        
        if layer == 0 then
            -- Layer 0: default surface, standard parameters
            layer_frequency = frequency
            layer_amplitude = amplitude
        elseif layer == 1 then
            -- Layer 1: slightly higher, smoother (front layer)
            layer_frequency = frequency * 0.8  -- Smoother
            layer_amplitude = amplitude * 0.7   -- Less variation
            layer_base = base_height + 3        -- Slightly higher (lower on screen)
        elseif layer == -1 then
            -- Layer -1: slightly lower, rougher (back layer for caves/mining)
            layer_frequency = frequency * 1.3   -- Rougher
            layer_amplitude = amplitude * 1.2   -- More variation
            layer_base = base_height - 5        -- Slightly lower (higher on screen)
        end
        
        -- Calculate surface height using Perlin noise
        local height_noise = noise.octave_perlin2d(col * layer_frequency, layer * 10, 4, 0.5, 2.0)
        local surface_y = math.floor(layer_base + height_noise * layer_amplitude)
        
        -- Determine dirt layer depth (5-15 blocks)
        local dirt_depth_noise = noise.perlin1d(col * 0.05 + layer * 100)
        local dirt_depth = math.floor(5 + (dirt_depth_noise * 0.5 + 0.5) * 10)
        
        -- Generate column from top to bottom
        for row = 0, world.HEIGHT - 1 do
            local depth = row - surface_y
            
            if depth < 0 then
                -- Air above surface
                w.layers[layer][col][row] = blocks.AIR
            elseif depth < dirt_depth then
                -- Dirt layer (5-15 blocks deep)
                if depth == 0 then
                    -- Top layer: will become grass if exposed to air
                    w.layers[layer][col][row] = blocks.GRASS
                else
                    w.layers[layer][col][row] = blocks.DIRT
                end
            else
                -- Underground: stone with ores
                local underground_noise = noise.perlin3d(col * 0.1, row * 0.1, layer * 50)
                
                -- Default to stone
                w.layers[layer][col][row] = blocks.STONE
                
                -- Add caves in layer -1 and 0 (more in -1)
                local cave_threshold = (layer == -1) and 0.6 or 0.7
                local cave_noise = noise.octave_perlin2d(col * 0.05, row * 0.05, 3, 0.5, 2.0)
                if depth > 10 and cave_noise > cave_threshold then
                    w.layers[layer][col][row] = blocks.AIR
                end
                
                -- Add ores based on depth and layer (only in stone, not caves)
                if w.layers[layer][col][row] == blocks.STONE then
                    -- Coal: appears at moderate depth
                    if depth > 10 and underground_noise > 0.65 then
                        local coal_noise = noise.perlin2d(col * 0.2, row * 0.2)
                        if coal_noise > 0.5 then
                            w.layers[layer][col][row] = blocks.COAL
                        end
                    end
                    
                    -- Copper: deeper, more common in layer -1
                    if depth > 15 and (layer == -1 or layer == 0) then
                        local copper_noise = noise.perlin2d(col * 0.15 + 100, row * 0.15)
                        if copper_noise > 0.7 then
                            w.layers[layer][col][row] = blocks.COPPER_ORE
                        end
                    end
                    
                    -- Iron: even deeper, primarily in layer -1
                    if depth > 25 and layer == -1 then
                        local iron_noise = noise.perlin2d(col * 0.12 + 200, row * 0.12)
                        if iron_noise > 0.75 then
                            w.layers[layer][col][row] = blocks.IRON_ORE
                        end
                    end
                end
            end
        end
        
        -- Second pass: ensure grass only on top of dirt exposed to air
        for row = 0, world.HEIGHT - 1 do
            if w.layers[layer][col][row] == blocks.GRASS then
                -- Check if there's air above
                if row > 0 then
                    local above = w.layers[layer][col][row - 1]
                    if above ~= blocks.AIR then
                        -- No air above, convert grass to dirt
                        w.layers[layer][col][row] = blocks.DIRT
                    end
                end
            elseif w.layers[layer][col][row] == blocks.DIRT then
                -- Check if this dirt should become grass (exposed to air)
                if row > 0 then
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
