local Object = require "core.object"
local GeneratorSystem = require "systems.generator"
local WorldDataComponent = require "components.worlddata"
local Registry = require "registries"
local BLOCKS = Registry.blocks()

local WorldSystem = Object.new {
    id = "world",
    priority = 10,
    HEIGHT = 512,
    canvases = {},
}

function WorldSystem.load(self, seed, _)
    -- Initialize components
    self.worlddata = WorldDataComponent.new(seed, self.HEIGHT)
    Log.info("World:", self.worlddata.seed)
    self.generator = require("systems.generator")

    -- Create canvases for layer rendering
    self:create_canvases()

    -- Pre-generate spawn area columns (32 to left and right of spawn)
    -- This ensures player doesn't spawn in the air waiting for terrain
    self.generator:pregenerate_spawn_area()

    Object.load(self)
end

function WorldSystem.create_canvases(self)
    local screen_width, screen_height = love.graphics.getDimensions()

    -- Create canvases for each layer
    self.canvases[-1] = love.graphics.newCanvas(screen_width, screen_height)
    self.canvases[0] = love.graphics.newCanvas(screen_width, screen_height)
    self.canvases[1] = love.graphics.newCanvas(screen_width, screen_height)
end

function WorldSystem.update(self, dt)
    Object.update(self, dt)
end

function WorldSystem.draw(self)
    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()

    local camera_x, camera_y = G.camera:get_offset()
    local player_x, player_y, player_z = G.player:get_position()

    -- Clear screen with sky blue background
    love.graphics.clear(0.4, 0.6, 0.9, 1)

    -- Calculate visible area
    local start_col = math.floor(camera_x / BLOCK_SIZE) - 1
    local end_col = math.ceil((camera_x + screen_width) / BLOCK_SIZE) + 1
    local start_row = math.floor(camera_y / BLOCK_SIZE) - 1
    local end_row = math.ceil((camera_y + screen_height) / BLOCK_SIZE) + 1

    -- Clamp to world bounds (vertical only - horizontal is infinite)
    start_row = math.max(0, start_row)
    end_row = math.min(self.HEIGHT - 1, end_row)

    -- Calculate max layer to render (from LAYER_MIN up to player_z + 1, clamped to LAYER_MAX)
    local max_layer = math.min(player_z + 1, LAYER_MAX)

    -- Draw each layer to its canvas
    for layer = LAYER_MIN, max_layer do
        local canvas = self.canvases[layer]
        if canvas then
            love.graphics.setCanvas(canvas)
            love.graphics.clear(0, 0, 0, 0)

            -- Check if this is the layer above the player
            local is_layer_above = (layer == player_z + 1)

            -- Set graphics state for outline drawing if this is the layer above
            if is_layer_above then
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.setLineWidth(1)
            end

            -- Draw blocks
            for col = start_col, end_col do
                for row = start_row, end_row do
                    local block_id = self:get_block_id(layer, col, row)
                    local proto = Registry.Blocks:get(block_id)

                    if proto and proto.solid then
                        local x = col * BLOCK_SIZE - camera_x
                        local y = row * BLOCK_SIZE - camera_y

                        if is_layer_above then
                            -- Draw only outlines for layer above player
                            -- Check each direction to see if there's air (draw edge if so)

                            -- Check top
                            local top_block = self:get_block_id(layer, col, row - 1)
                            local top_proto = Registry.Blocks:get(top_block)
                            if not (top_proto and top_proto.solid) then
                                love.graphics.line(x, y, x + BLOCK_SIZE, y)
                            end

                            -- Check bottom
                            local bottom_block = self:get_block_id(layer, col, row + 1)
                            local bottom_proto = Registry.Blocks:get(bottom_block)
                            if not (bottom_proto and bottom_proto.solid) then
                                love.graphics.line(x, y + BLOCK_SIZE, x + BLOCK_SIZE, y + BLOCK_SIZE)
                            end

                            -- Check left
                            local left_block = self:get_block_id(layer, col - 1, row)
                            local left_proto = Registry.Blocks:get(left_block)
                            if not (left_proto and left_proto.solid) then
                                love.graphics.line(x, y, x, y + BLOCK_SIZE)
                            end

                            -- Check right
                            local right_block = self:get_block_id(layer, col + 1, row)
                            local right_proto = Registry.Blocks:get(right_block)
                            if not (right_proto and right_proto.solid) then
                                love.graphics.line(x + BLOCK_SIZE, y, x + BLOCK_SIZE, y + BLOCK_SIZE)
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

            love.graphics.setCanvas()
        end
    end

    -- Composite layers to screen (only the layers we rendered: LAYER_MIN to player_z + 1)
    -- Set blend mode to ensure proper layering (solid blocks should completely cover layers below)
    love.graphics.setBlendMode("alpha", "premultiplied")

    -- Draw each layer from LAYER_MIN to max_layer
    for layer = LAYER_MIN, max_layer do
        local canvas = self.canvases[layer]
        if canvas then
            if layer == player_z then
                -- Full color: player is on this layer
                love.graphics.setColor(1, 1, 1, 1)
            elseif layer == player_z + 1 then
                -- Full color: this is the layer above player (outlines already have alpha)
                love.graphics.setColor(1, 1, 1, 1)
            else
                -- Dimmed: layers below player
                love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            end
            love.graphics.draw(canvas, 0, 0)
        end
    end

    -- Reset blend mode to default
    love.graphics.setBlendMode("alpha")

    Object.draw(self)
end

-- Check if a location is valid for building
function WorldSystem.is_valid_building_location(self, col, row, layer)
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
function WorldSystem.get_block_id(self, z, col, row)
    if row < 0 or row >= self.worlddata.height then
        return BLOCKS.AIR
    end

    -- Request column generation with high priority (visible column)
    self.generator:generate_column(z, col, true)

    local data = self.worlddata
    if data.columns[z] and
       data.columns[z][col] and
       data.columns[z][col][row] then
        return data.columns[z][col][row]
    end

    return BLOCKS.AIR
end

-- Get block prototype at position
function WorldSystem.get_block_def(self, z, col, row)
    local block_id = self.get_block_id(self, z, col, row)
    return Registry.Blocks:get(block_id)
end

-- Set block at position
function WorldSystem.set_block(self, z, col, row, block_id)
    if row < 0 or row >= self.worlddata.height then
        return false
    end

    -- Request column generation with high priority (user action)
    self.generator:generate_column(z, col, true)

    local data = self.worlddata

    -- Ensure the column structure exists
    if not data.columns[z] then
        data.columns[z] = {}
    end
    if not data.columns[z][col] then
        data.columns[z][col] = {}
    end

    data.columns[z][col][row] = block_id
    return true
end

-- World to block coordinate conversion
function WorldSystem.world_to_block(self, world_x, world_y)
    return math.floor(world_x / BLOCK_SIZE), math.floor(world_y / BLOCK_SIZE)
end

-- Block to world coordinate conversion
function WorldSystem.block_to_world(self, col, row)
    return col * BLOCK_SIZE, row * BLOCK_SIZE
end

-- Find spawn position (simplified)
function WorldSystem.find_spawn_position(self, z)
    z = z or 0
    -- Find the surface by searching for the first solid block from top
    local col = BLOCK_SIZE
    for row = 0, self.worlddata.height - 1 do
        local block_def = self.get_block_def(self, z, col, row)
        if block_def and block_def.solid then
            -- Spawn in the last air block (just above the ground)
            -- This ensures the player spawns on the surface, not inside it
            local spawn_x = col * BLOCK_SIZE + BLOCK_SIZE / 2
            local spawn_y = (row - 1) * BLOCK_SIZE + BLOCK_SIZE / 2
            return spawn_x, spawn_y, z
        end
    end

    -- Default spawn at top if no ground found
    return col * BLOCK_SIZE, 0, z
end

function WorldSystem.resize(self, width, height)
    self:create_canvases()
    Object.resize(self, width, height)
end

return WorldSystem
