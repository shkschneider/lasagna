local Love = require "core.love"
local Object = require "core.object"
local Registry = require "registries"
local BLOCKS = Registry.blocks()

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
    for z = LAYER_MIN, LAYER_MAX do
        self:draw_layer(z)
    end
end

function World.draw_layer(self, layer)
    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()

    local camera_x, camera_y = G.camera:get_offset()
    local player_x, player_y, player_z = G.player:get_position()

    -- Calculate visible area
    local start_col = math.floor(camera_x / BLOCK_SIZE) - 1
    local end_col = math.ceil((camera_x + screen_width) / BLOCK_SIZE) + 1
    local start_row = math.floor(camera_y / BLOCK_SIZE) - 1
    local end_row = math.ceil((camera_y + screen_height) / BLOCK_SIZE) + 1

    -- Clamp to world bounds (vertical only - horizontal is infinite)
    start_row = math.max(0, start_row)
    end_row = math.min(self.HEIGHT - 1, end_row)

    -- Check if this is the layer above the player
    local is_layer_above = (layer >= player_z + 1)

    -- Draw blocks
    for col = start_col, end_col do
        for row = start_row, end_row do
            local block_id = self:get_block_id(layer, col, row)
            local proto = Registry.Blocks:get(block_id)

            if proto and proto.solid then
                local x = col * BLOCK_SIZE - camera_x
                local y = row * BLOCK_SIZE - camera_y

                if is_layer_above then
                    -- For layers above player, only draw blocks that have air on top
                    local top_block = self:get_block_id(layer, col, row - 1)
                    local top_proto = Registry.Blocks:get(top_block)
                    if not (top_proto and top_proto.solid) then
                        -- Draw this block with semi-transparency
                        local r, g, b = proto.color[1] or 1, proto.color[2] or 1, proto.color[3] or 1
                        love.graphics.setColor(r, g, b, 0.5)
                        love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)
                    end
                else
                    -- Normal filled blocks for other layers
                    -- Ensure blocks are drawn with full opacity (alpha=1) to properly cover layers below
                    local r, g, b = proto.color[1] or 1, proto.color[2] or 1, proto.color[3] or 1
                    love.graphics.setColor(r, g, b, 1)
                    love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)
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

-- Get block at position
function World.get_block_id(self, z, col, row)
    if row < 0 or row >= self.HEIGHT then
        return BLOCKS.AIR
    end

    -- Request column generation with high priority (visible column)
    self.generator:generate_column(z, col, true)

    local data = self.generator.data
    if data.columns[z] and
       data.columns[z][col] and
       data.columns[z][col][row] then
        return data.columns[z][col][row]
    end

    return BLOCKS.AIR
end

-- Get block prototype at position
function World.get_block_def(self, z, col, row)
    local block_id = self.get_block_id(self, z, col, row)
    return Registry.Blocks:get(block_id)
end

-- Set block at position
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

    -- Track change from generated terrain
    if not data.changes[z] then
        data.changes[z] = {}
    end
    if not data.changes[z][col] then
        data.changes[z][col] = {}
    end
    data.changes[z][col][row] = block_id

    data.columns[z][col][row] = block_id
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
        local block_def = self.get_block_def(self, z, col, row)
        if block_def and block_def.solid then
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
