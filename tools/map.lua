#!/usr/bin/env lua
-- tools/map.lua
-- Generate ASCII map of the spawn area surface for a given seed
-- Usage: lua tools/map.lua <seed>
--
-- This tool uses the actual game's world generator to produce accurate terrain maps.

-- Parse command line arguments
local seed = tonumber(arg[1])
if not seed then
    print("Usage: lua tools/map.lua <seed>")
    print("Example: lua tools/map.lua 12345")
    os.exit(1)
end

-- Setup minimal LÖVE environment for world generation
love = love or {}

-- Mock love.math.noise with built-in Lua functionality
-- LÖVE uses simplex noise which we need to approximate
if not love.math then
    love.math = {}
end

if not love.math.noise then
    -- Simple noise implementation using Lua's math library
    -- This approximates simplex noise behavior for terrain generation
    function love.math.noise(x, y, z)
        y = y or 0
        z = z or 0
        -- Hash the coordinates to get a pseudo-random value
        local n = x * 374761393 + y * 668265263 + z * 1274126177
        n = math.abs(n) % 2147483647
        n = (n * n * 15731 + 789221) % 2147483647
        n = (n + 1376312589) % 2147483647
        return (n % 1000000) / 1000000.0
    end
end

love.graphics = love.graphics or {
    getDimensions = function() return 800, 600 end,
}
love.timer = love.timer or {
    getTime = function() return os.clock() end,
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
SPAWN_COL = BLOCK_SIZE  -- Spawn column matches the find_spawn_position in World

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

-- Mock math functions if not available
math.clamp = math.clamp or function(val, min, max)
    return math.max(min, math.min(max, val))
end

math.round = math.round or function(val)
    return math.floor(val + 0.5)
end

-- Load required modules
local BlockRef = require("data.blocks.ids")
local WorldSeed = require("src.world.seed")

-- Load the actual world generator
local Generator = require("src.world.generator")

-- Find surface row for a column (first non-air/non-sky block)
local function find_surface_row(column_data, world_height)
    for row = 0, world_height - 1 do
        local value = column_data[row]
        if value and value ~= BlockRef.SKY and value ~= BlockRef.AIR then
            return row
        end
    end
    return nil
end

-- Generate and display ASCII map with elevation
local function generate_map(seed_val)
    print(string.format("Generating map for seed: %d", seed_val))
    print("")
    
    local world_height = 512
    local spawn_col = SPAWN_COL
    
    -- Determine map size (visible area around spawn)
    local map_width = 80  -- 80 characters wide
    local start_col = spawn_col - math.floor(map_width / 2)
    
    -- Initialize the generator with the seed
    local generator = Generator
    generator.data = WorldSeed.new(seed_val, world_height)
    generator:load()
    
    -- Generate for each layer
    for z = LAYER_MIN, LAYER_MAX do
        print(string.format("Layer %d:", z))
        print(string.rep("-", map_width))
        
        -- Generate columns for this layer
        local surface_rows = {}
        local min_surface = math.huge
        local max_surface = -math.huge
        
        for col = start_col, start_col + map_width - 1 do
            generator:generate_column_immediate(z, col)
            local column_data = generator.data.columns[z] and generator.data.columns[z][col]
            if column_data then
                local surface_row = find_surface_row(column_data, world_height)
                surface_rows[col] = surface_row
                
                if surface_row then
                    min_surface = math.min(min_surface, surface_row)
                    max_surface = math.max(max_surface, surface_row)
                end
            end
        end
        
        -- Check if any surface was found
        if min_surface == math.huge then
            print("No surface found")
            print("")
        else
            -- Calculate display range (show terrain with elevation)
            local display_height = 20  -- Show 20 rows of terrain
            local mid_surface = math.floor((min_surface + max_surface) / 2)
            local start_row = mid_surface - math.floor(display_height / 2)
            local end_row = start_row + display_height - 1
            
            -- Generate 2D ASCII map showing elevation
            for row = start_row, end_row do
                local line = ""
                for col = start_col, start_col + map_width - 1 do
                    local surface_row = surface_rows[col]
                    local is_spawn = (col == spawn_col and z == LAYER_DEFAULT)
                    
                    if row < 0 or row >= world_height then
                        line = line .. " "
                    elseif not surface_row then
                        line = line .. " "
                    elseif row < surface_row then
                        -- Above surface = sky/air
                        if is_spawn and row == surface_row - 1 then
                            line = line .. "X"  -- Mark spawn position above surface
                        else
                            line = line .. " "
                        end
                    else
                        -- At or below surface = ground
                        if is_spawn and row == surface_row then
                            line = line .. "X"  -- Mark spawn position at surface
                        else
                            line = line .. "_"
                        end
                    end
                end
                print(line)
            end
            
            print("")
        end
    end
    
    print(string.format("Spawn position: column %d, layer %d", spawn_col, LAYER_DEFAULT))
end

-- Run the map generation
generate_map(seed)
