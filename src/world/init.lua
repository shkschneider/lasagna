local Love = require "core.love"
local Object = require "core.object"
local Registry = require "registries"
local BLOCKS = Registry.blocks()
local BlockRef = require "data.blocks.ids"

-- Special marker values for surface blocks (must match generator.lua)
local MARKER_GRASS = -1
local MARKER_DIRT = -2

-- Block mapping for value ranges (value * 10 = index)
-- Maps noise values to actual terrain block types
local VALUE_TO_BLOCK = {
    [1] = BlockRef.MUD,        -- 0.1-0.2: Mud (wet areas, caves)
    [2] = BlockRef.GRAVEL,     -- 0.2-0.3: Gravel
    [3] = BlockRef.CLAY,       -- 0.3-0.4: Clay
    [4] = BlockRef.DIRT,       -- 0.4-0.5: Dirt
    [5] = BlockRef.SAND,       -- 0.5-0.6: Sand
    [6] = BlockRef.SANDSTONE,  -- 0.6-0.7: Sandstone
    [7] = BlockRef.LIMESTONE,  -- 0.7-0.8: Limestone
    [8] = BlockRef.STONE,      -- 0.8-0.9: Stone
    [9] = BlockRef.GRANITE,    -- 0.9-1.0: Granite
    [10] = BlockRef.BASALT,    -- 1.0: Basalt (deepest)
}

local World = Object {
    HEIGHT = 512,
    id = "world",
    priority = 10,
    generator = require("src.world.generator"),
    save = require("src.world.save"),
}

function World.load(self)
    Love.load(self)
end

function World.update(self, dt)
    Love.update(self, dt)
end

function World.draw(self)
    if G.debug then
        self:draw_layer(G.player.position.z)
    else
        for z = LAYER_MIN, LAYER_MAX do
            self:draw_layer(z)
        end
    end
end

function World.draw_layer(self, layer)
    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()

    local camera_x, camera_y = G.camera:get_offset()

    -- Calculate visible area
    local start_col = math.floor(camera_x / BLOCK_SIZE) - 1
    local end_col = math.ceil((camera_x + screen_width) / BLOCK_SIZE) + 1
    local start_row = math.floor(camera_y / BLOCK_SIZE) - 1
    local end_row = math.ceil((camera_y + screen_height) / BLOCK_SIZE) + 1

    -- Clamp to world bounds (vertical only - horizontal is infinite)
    start_row = math.max(0, start_row)
    end_row = math.min(self.HEIGHT - 1, end_row)

    -- Draw blocks using actual block colors based on value ranges
    for col = start_col, end_col do
        for row = start_row, end_row do
            local value = self:get_block_value(layer, col, row)

            -- value ~= 0 means it's not air
            if value ~= 0 then
                local x = col * BLOCK_SIZE - camera_x
                local y = row * BLOCK_SIZE - camera_y
                local block_id = nil

                -- Check for special marker values (surface blocks)
                if value == MARKER_GRASS then
                    block_id = BlockRef.GRASS
                elseif value == MARKER_DIRT then
                    block_id = BlockRef.DIRT
                elseif value > 0 then
                    -- Map noise value to block type: 0.1-0.2 = 1, 0.2-0.3 = 2, etc.
                    local block_index = math.floor(value * 10)
                    -- Clamp to valid range (1-10)
                    block_index = math.max(1, math.min(10, block_index))
                    block_id = VALUE_TO_BLOCK[block_index]
                end

                if block_id then
                    local block = Registry.Blocks:get(block_id)
                    if block and block.color then
                        love.graphics.setColor(block.color[1], block.color[2], block.color[3], block.color[4] or 1)
                        love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)
                    end
                end
            end
        end
    end
end

-- Check if a location is valid for building
function World.is_valid_building_location(self, col, row, layer)
    -- Check if spot is empty (air)
    local current_block = self:get_block_id(layer, col, row)
    if current_block ~= BLOCKS.AIR then
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

-- Get raw noise value at position (0.0-1.0 range, 0 = air)
function World.get_block_value(self, z, col, row)
    if row < 0 or row >= self.HEIGHT then
        return 0
    end

    -- Request column generation with high priority (visible column)
    self.generator:generate_column(z, col, true)

    local data = self.generator.data
    if data.columns[z] and
       data.columns[z][col] and
       data.columns[z][col][row] then
        return data.columns[z][col][row]
    end

    return 0
end

-- Get block at position (returns block ID based on value)
function World.get_block_id(self, z, col, row)
    local value = self:get_block_value(z, col, row)
    -- Check for special marker values (surface blocks)
    if value == MARKER_GRASS then
        return BlockRef.GRASS
    elseif value == MARKER_DIRT then
        return BlockRef.DIRT
    elseif value > 0 then
        -- Map noise value to block type
        local block_index = math.floor(value * 10)
        block_index = math.max(1, math.min(10, block_index))
        return VALUE_TO_BLOCK[block_index] or BlockRef.STONE
    end
    return BlockRef.AIR
end

-- Get block prototype at position
function World.get_block_def(self, z, col, row)
    local block_id = self.get_block_id(self, z, col, row)
    return Registry.Blocks:get(block_id)
end

-- Set block value at position (0 = air, 1 = solid)
function World.set_block(self, z, col, row, block_id)
    local data = self.generator.data
    if row < 0 or row >= data.height then
        return false
    end

    -- Request column generation with high priority (user action)
    self.generator:generate_column(z, col, true)

    -- Ensure the column structure exists
    if not data.columns[z] then
        data.columns[z] = {}
    end
    if not data.columns[z][col] then
        data.columns[z][col] = {}
    end

    -- Convert block ID to noise value (0 = air, 1 = solid)
    local value = (block_id == BLOCKS.AIR) and 0 or 1

    -- Track change from generated terrain
    if not data.changes[z] then
        data.changes[z] = {}
    end
    if not data.changes[z][col] then
        data.changes[z][col] = {}
    end
    data.changes[z][col][row] = value

    data.columns[z][col][row] = value
    return true
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
    z = z or 0
    -- Find the surface by searching for the first solid block from top
    local col = BLOCK_SIZE
    for row = 0, self.HEIGHT - 1 do
        local value = self:get_block_value(z, col, row)
        -- value > 0 means solid ground (generator already applied SOLID threshold)
        if value > 0 then
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
