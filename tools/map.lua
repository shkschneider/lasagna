#!/usr/bin/env lua
-- tools/map.lua
-- Generate ASCII map of the spawn area surface for a given seed
-- Usage: lua tools/map.lua <seed>
--
-- NOTE: This tool uses a simplified noise function and terrain generation
-- algorithm compared to the actual game. The output provides a general
-- representation of terrain patterns but may not exactly match the game's
-- world generation due to differences in noise implementation (LÖVE's
-- simplex noise vs. our hash-based approximation).

-- Parse command line arguments
local seed = tonumber(arg[1])
if not seed then
    print("Usage: lua tools/map.lua <seed>")
    print("Example: lua tools/map.lua 12345")
    os.exit(1)
end

-- Setup minimal environment for world generation
-- Mock LÖVE functions and globals

-- Simple hash-based noise function for terrain generation
local function simple_noise(x, y, seed_offset)
    -- Create a hash from inputs using simple math operations
    local n = x * 374761393 + y * 668265263 + seed_offset * 1274126177
    -- Ensure n is positive and in a reasonable range
    n = math.abs(n) % 2147483647
    -- Multiple passes to mix the bits
    n = (n * n * 15731 + 789221) % 2147483647
    n = (n + 1376312589) % 2147483647
    -- Return value in [0, 1] range
    return (n % 1000000) / 1000000.0
end

love = {
    math = {
        noise = function(x, y, z)
            -- Use x, y as coordinates and z as seed
            y = y or 0
            z = z or 0
            return simple_noise(x, y, z)
        end,
    },
    graphics = {
        getDimensions = function()
            return 800, 600
        end,
    },
    timer = {
        getTime = function()
            return os.clock()
        end,
    },
}

-- Mock logger
Log = {
    info = function(...) end,
    debug = function(...) end,
    verbose = function(...) end,
    error = function(...) print("ERROR:", ...) end,
}

-- Global constants
BLOCK_SIZE = 16
LAYER_MIN = -1
LAYER_DEFAULT = 0
LAYER_MAX = 1

-- Mock G object
G = {
    debug = false,
    loader = nil,
}

-- Mock core modules
package.loaded["core.object"] = function(tbl) return tbl end
package.loaded["core.love"] = {
    load = function() end,
    update = function() end,
}

-- Load required modules
local BlockRef = require("data.blocks.ids")
local WorldSeed = require("src.world.seed")

-- We need to partially load the generator
-- Copy the essential generation logic here to avoid complex dependencies
local function generate_column_terrain(column_data, col, z, world_height, seed_val)
    -- Set up noise seed
    local seed_offset = seed_val % 10000
    local biome_seed_offset = (seed_val % 10000) + 1000
    
    -- Surface parameters
    local SURFACE_Y_RATIO = 0.25
    local SOLID = 0.33
    local NOISE_OFFSET = 100
    
    -- Noise functions
    local function simplex1d(x)
        return love.math.noise(x, seed_offset)
    end
    
    local function simplex2d(x, y)
        return love.math.noise(x, y, seed_offset)
    end
    
    -- Multi-octave noise parameters
    local HILL_FREQUENCY = 0.005
    local HILL_AMPLITUDE = 0.08
    local TERRAIN_VAR_FREQUENCY = 0.02
    local TERRAIN_VAR_AMPLITUDE = 0.03
    local DETAIL_FREQUENCY = 0.08
    local DETAIL_AMPLITUDE = 0.01
    local SURFACE_SMOOTHNESS = 0.75
    local Z_SCALE_FACTOR = 0.1
    local TERRAIN_FREQUENCY = 0.05
    
    -- Multi-octave surface noise
    local function organic_surface_noise(col, z)
        local hills = (simplex1d(col * HILL_FREQUENCY + z * Z_SCALE_FACTOR) - 0.5) * 2 * HILL_AMPLITUDE
        local medium_factor = 1.0 - (SURFACE_SMOOTHNESS * 0.5)
        local variation = (simplex1d(col * TERRAIN_VAR_FREQUENCY + z * Z_SCALE_FACTOR + 100) - 0.5) * 2 * TERRAIN_VAR_AMPLITUDE * medium_factor
        local detail_factor = 1.0 - SURFACE_SMOOTHNESS
        local detail = (simplex1d(col * DETAIL_FREQUENCY + z * Z_SCALE_FACTOR + 200) - 0.5) * 2 * DETAIL_AMPLITUDE * detail_factor
        return hills + variation + detail
    end
    
    -- Calculate surface
    local surface_offset = organic_surface_noise(col, z)
    local cut_ratio = SURFACE_Y_RATIO + surface_offset
    local cut_row = math.floor(world_height * cut_ratio)
    cut_row = math.max(1, math.min(world_height - 3, cut_row))
    
    -- Fill column
    for row = 0, world_height - 1 do
        if row < cut_row then
            column_data[row] = BlockRef.SKY
        else
            local terrain_value = simplex2d(col * TERRAIN_FREQUENCY, row * TERRAIN_FREQUENCY + z * 10)
            if terrain_value < SOLID then
                column_data[row] = BlockRef.SKY
            else
                column_data[row] = NOISE_OFFSET + math.floor(terrain_value * 100)
            end
        end
    end
    
    -- Find surface and add surface blocks
    local surface_row = nil
    for row = 0, world_height - 1 do
        if column_data[row] and column_data[row] > BlockRef.AIR then
            surface_row = row
            break
        end
    end
    
    -- Simple surface layer (using grass/dirt for simplicity)
    if surface_row and surface_row > 0 then
        -- Add a grass block at surface
        if surface_row - 1 >= 0 then
            column_data[surface_row - 1] = BlockRef.GRASS
        end
    end
    
    -- Convert underground SKY to AIR
    local found_solid = false
    for row = 0, world_height - 1 do
        local block = column_data[row]
        if block ~= BlockRef.SKY and block ~= BlockRef.AIR then
            found_solid = true
        end
        if found_solid and block == BlockRef.SKY then
            column_data[row] = BlockRef.AIR
        end
    end
end

-- Find surface row for a column
local function find_surface_row(column_data, world_height)
    for row = 0, world_height - 1 do
        local value = column_data[row]
        if value and value ~= BlockRef.SKY and value ~= BlockRef.AIR then
            return row
        end
    end
    return nil
end

-- Generate and display ASCII map
local function generate_map(seed_val)
    print(string.format("Generating map for seed: %d", seed_val))
    print("")
    
    local world_height = 512
    local spawn_col = BLOCK_SIZE
    
    -- Determine map size (visible area around spawn)
    local map_width = 80  -- 80 characters wide
    local start_col = spawn_col - math.floor(map_width / 2)
    
    -- Generate for each layer
    for z = LAYER_MIN, LAYER_MAX do
        print(string.format("Layer %d:", z))
        print(string.rep("-", map_width))
        
        -- Generate columns for this layer
        local columns = {}
        local min_surface = math.huge
        local max_surface = -math.huge
        
        for col = start_col, start_col + map_width - 1 do
            local column_data = {}
            generate_column_terrain(column_data, col, z, world_height, seed_val)
            columns[col] = column_data
            
            local surface_row = find_surface_row(column_data, world_height)
            if surface_row then
                min_surface = math.min(min_surface, surface_row)
                max_surface = math.max(max_surface, surface_row)
            end
        end
        
        -- Determine vertical range to display
        -- Check if any surface was found
        if min_surface == math.huge then
            print("No surface found")
            print("")
        else
            -- Generate ASCII map showing surface line
            -- Build surface map first
            local surface_map = {}
            for col = start_col, start_col + map_width - 1 do
                local column_data = columns[col]
                local surface_row = find_surface_row(column_data, world_height)
                surface_map[col] = surface_row
            end
            
            -- Draw only surface level with spawn marker
            local line = ""
            for col = start_col, start_col + map_width - 1 do
                local is_spawn = (col == spawn_col and z == LAYER_DEFAULT)
                
                if is_spawn then
                    line = line .. "X"
                elseif surface_map[col] then
                    line = line .. "_"
                else
                    line = line .. " "
                end
            end
            print(line)
            
            print("")
        end
    end
    
    print(string.format("Spawn position: column %d, layer %d", spawn_col, LAYER_DEFAULT))
end

-- Run the map generation
generate_map(seed)
