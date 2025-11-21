-- World generation and block storage
-- Three layers: -1 (back), 0 (main), 1 (front)
-- Lazy column generation with seeded noise

local blocks = require("blocks")

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
    
    -- Initialize random with seed
    math.randomseed(w.seed)
    
    return w
end

-- Simple noise function (placeholder)
local function noise(x, y, seed)
    -- Simple pseudo-random function based on position and seed
    local n = x * 374761393 + y * 668265263 + seed * 1013904223
    n = (n * n * n * 60493 + n * 19990303) % 2147483647
    return (n % 10000) / 10000.0 - 0.5
end

-- Generate a single column across all layers
function world.generate_column(w, col)
    if w.generated_columns[col] then
        return
    end
    
    -- Generate height for this column using noise
    local base_height = math.floor(world.HEIGHT * 0.6)
    local height_offset = math.floor(noise(col, 0, w.seed) * 10)
    local surface_y = base_height + height_offset
    
    for layer = -1, 1 do
        if not w.layers[layer][col] then
            w.layers[layer][col] = {}
        end
        
        -- Layer-specific terrain variation
        local layer_offset = layer * 2
        
        for row = 0, world.HEIGHT - 1 do
            local depth = row - surface_y - layer_offset
            
            if depth < 0 then
                -- Air above surface
                w.layers[layer][col][row] = blocks.AIR
            elseif depth < 3 then
                -- Top soil layer
                w.layers[layer][col][row] = blocks.DIRT
            else
                -- Underground
                local rock_noise = noise(col, row, w.seed + layer)
                
                -- Stone is primary
                w.layers[layer][col][row] = blocks.STONE
                
                -- Add some ores based on depth and noise
                if depth > 10 and rock_noise > 0.7 then
                    w.layers[layer][col][row] = blocks.COAL
                elseif depth > 15 and layer == -1 and rock_noise > 0.85 then
                    w.layers[layer][col][row] = blocks.COPPER_ORE
                elseif depth > 20 and layer == -1 and rock_noise > 0.9 then
                    w.layers[layer][col][row] = blocks.IRON_ORE
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

return world
