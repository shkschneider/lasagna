local Love = require "core.love"
local Object = require "core.object"
local BlockRef = require "data.blocks.ids"
local Biome = require "src.world.biome"
local Layer = require "src.world.layer"

World = Object {
    HEIGHT = 512,
    id = "world",
    priority = 10,
    generator = require("src.world.generator"),
    save = require("src.world.save"),
    -- Block ID offset: noise values are stored as NOISE_OFFSET + value*100
    -- Block IDs 0-99 are actual blocks, 100+ are noise values
    NOISE_OFFSET = 100,
    -- Biome zone size in blocks (512x512 zones)
    BIOME_ZONE_SIZE = Biome.ZONE_SIZE,
}

local here = (...):gsub("%.init$", "") .. "."
require(here .. "_get")
require(here .. "_set")
require(here .. "_draw")

function World.load(self)
    Love.load(self)
    -- Set biome seed offset after generator loads (generator sets its seed in its load)
    self.biome_seed_offset = (self.generator.data.seed % 10000) + 1000
    
    -- Initialize layers after Love.load to avoid them being included in recursive load
    self.background_layer = Layer.new("background", self)
    self.foreground_layer = Layer.new("foreground", self)
end

function World.update(self, dt)
    Love.update(self, dt)
end

-- Check if a location is valid for building
function World.is_valid_building_location(self, col, row, layer)
    -- Check if spot is empty (sky or air)
    local current_block = self:get_block_id(layer, col, row)
    if current_block ~= BlockRef.SKY and current_block ~= BlockRef.AIR then
        return false
    end

    -- Check for adjacent blocks in same layer (8 directions)
    local offsets = {
        {-1, -1}, {0, -1}, {1, -1},  -- top row
        {-1,  0},          {1,  0},  -- middle row (left and right)
        {-1,  1}, {0,  1}, {1,  1},  -- bottom row
    }

    for _, offset in ipairs(offsets) do
        local check_col = col + offset[1]
        local check_row = row + offset[2]
        local proto = self:get_block_def(layer, check_col, check_row)
        if proto and proto.solid then
            return true
        end
    end

    -- Check for blocks in adjacent layers at same position
    if layer - 1 >= LAYER_MIN then
        local proto = self:get_block_def(layer - 1, col, row)
        if proto and proto.solid then
            return true
        end
    end

    if layer + 1 <= LAYER_MAX then
        local proto = self:get_block_def(layer + 1, col, row)
        if proto and proto.solid then
            return true
        end
    end

    return false
end

-- Check if a position has direct access to the sky (no solid blocks above it)
-- Returns true if there's only sky from this position up to row 0 (top of world)
-- Note: This is now O(1) efficient - just check if the block is SKY (not AIR)
function World.has_access_to_sky(self, z, col, row)
    -- A block has sky access if it's SKY (0), not AIR (1) which is underground
    local value = self:get_block_value(z, col, row)
    return value == BlockRef.SKY
end

-- World to block coordinate conversion
function World.world_to_block(self, world_x, world_y)
    return math.floor(world_x / BLOCK_SIZE), math.floor(world_y / BLOCK_SIZE)
end

-- Block to world coordinate conversion
function World.block_to_world(self, col, row)
    return col * BLOCK_SIZE, row * BLOCK_SIZE
end

function World.can_switch_layer(self, target_layer)
    if target_layer < LAYER_MIN or target_layer > LAYER_MAX then
        return false
    end
    return true
end

-- Find spawn position (simplified)
function World.find_spawn_position(self, z)
    z = z or LAYER_DEFAULT
    -- Find the surface by searching for the first solid block from top
    local col = BLOCK_SIZE
    for row = 0, self.HEIGHT - 1 do
        local value = self:get_block_value(z, col, row)
        -- Check for solid ground: positive values or marker values (grass/dirt are solid)
        -- value > 0 = noise-based terrain, MARKER_GRASS = -1, MARKER_DIRT = -2
        if value ~= 0 then
            -- Spawn above the ground
            -- Player is 2 blocks tall and position is at center
            -- Subtract player height to ensure player is fully above ground
            local spawn_x = col * BLOCK_SIZE + BLOCK_SIZE / 2
            local spawn_y = (row - 1) * BLOCK_SIZE
            return spawn_x, spawn_y, z
        end
    end

    -- Default spawn at top if no ground found
    return col * BLOCK_SIZE, 0, z
end

function World.resize(self, width, height)
    Love.resize(self, width, height)
end

return World
