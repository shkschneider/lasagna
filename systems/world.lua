-- World System
-- Manages world generation, block storage, and world queries

local log = require "lib.log"
local WorldGen = require "core.worldgen"

local Systems = require "systems"
local WorldData = require "components.worlddata"
local Registry = require "registries"

local ONLY_CURRENT_LAYER_VISIBLE = false

local BLOCKS = Registry.blocks()

local WorldSystem = {
    id = "world",
    priority = 10,
    components = {},
    WIDTH = 512,
    HEIGHT = 512,
    canvases = {},
}

function WorldSystem.load(self, seed, debug)
    -- Initialize components
    self.components.worlddata = WorldData.new(seed, self.WIDTH, self.HEIGHT)
    log.info("World:", self.components.worlddata.seed)

    -- Seed the noise library
    noise.seed(self.components.worlddata.seed)

    -- Create canvases for layer rendering
    self:create_canvases()
end

function WorldSystem.create_canvases(self)
    local screen_width, screen_height = love.graphics.getDimensions()

    -- Create canvases for each layer
    self.canvases[-1] = love.graphics.newCanvas(screen_width, screen_height)
    self.canvases[0] = love.graphics.newCanvas(screen_width, screen_height)
    self.canvases[1] = love.graphics.newCanvas(screen_width, screen_height)
end

function WorldSystem.update(self, dt)
    -- World generation happens on-demand in get_block
end

function WorldSystem.draw(self)
    local player = Systems.get("player")
    local camera = Systems.get("camera")

    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()

    local camera_x, camera_y = camera:get_offset()
    local player_x, player_y, player_z = player:get_position()

    -- Clear screen with sky blue background
    love.graphics.clear(0.4, 0.6, 0.9, 1)

    -- Calculate visible area
    local start_col = math.floor(camera_x / BLOCK_SIZE) - 1
    local end_col = math.ceil((camera_x + screen_width) / BLOCK_SIZE) + 1
    local start_row = math.floor(camera_y / BLOCK_SIZE) - 1
    local end_row = math.ceil((camera_y + screen_height) / BLOCK_SIZE) + 1

    -- Clamp to world bounds
    start_col = math.max(0, start_col)
    end_col = math.min(self.WIDTH - 1, end_col)
    start_row = math.max(0, start_row)
    end_row = math.min(self.HEIGHT - 1, end_row)

    -- Draw each layer to its canvas
    for layer = LAYER_MIN, LAYER_MAX do
        local canvas = self.canvases[layer]
        if canvas then
            love.graphics.setCanvas(canvas)
            love.graphics.clear(0, 0, 0, 0)

            -- Draw blocks
            for col = start_col, end_col do
                for row = start_row, end_row do
                    local block_id = self:get_block_id(layer, col, row)
                    local proto = Registry.Blocks:get(block_id)

                    if proto and proto.solid then
                        -- Ensure blocks are drawn with full opacity (alpha=1) to properly cover layers below
                        local r, g, b = proto.color[1] or 1, proto.color[2] or 1, proto.color[3] or 1
                        love.graphics.setColor(r, g, b, 1)
                        local x = col * BLOCK_SIZE - camera_x
                        local y = row * BLOCK_SIZE - camera_y
                        love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)
                    end
                end
            end

            love.graphics.setCanvas()
        end
    end

    -- Composite layers to screen
    -- Set blend mode to ensure proper layering (solid blocks should completely cover layers below)
    love.graphics.setBlendMode("alpha", "premultiplied")

    local debug = Systems.get("debug")

    if not ONLY_CURRENT_LAYER_VISIBLE or (debug and (not debug.enabled or player_z == -1)) then
        -- Draw back layer (dimmed)
        if self.canvases[-1] then
            if player_z == -1 then
                love.graphics.setColor(1, 1, 1, 1)
            else
                love.graphics.setColor(0.5, 0.5, 0.5, 0.5) -- Dimmed
            end
            love.graphics.draw(self.canvases[-1], 0, 0)
        end
    end

    if not ONLY_CURRENT_LAYER_VISIBLE or (debug and (not debug.enabled or player_z == 0)) then
        -- Draw main layer
        if self.canvases[0] then
            if player_z == 0 then
                love.graphics.setColor(1, 1, 1, 1)
            else
                love.graphics.setColor(0.5, 0.5, 0.5, 0.5) -- Dimmed
            end
            love.graphics.draw(self.canvases[0], 0, 0)
        end
    end

    if not ONLY_CURRENT_LAYER_VISIBLE or (debug and (not debug.enabled or player_z == 1)) then
        -- Draw front layer (semi-transparent)
        if self.canvases[1] then
            if player_z == 1 then
                love.graphics.setColor(1, 1, 1, 1)
            else
                love.graphics.setColor(0.33, 0.33, 0.33, 0.33) -- Very dimmed
            end
            love.graphics.draw(self.canvases[1], 0, 0)
        end
    end

    -- Reset blend mode to default
    love.graphics.setBlendMode("alpha")
end

-- Generate a column if not already generated
function WorldSystem.generate_column(self, z, col)
    local data = self.components.worlddata

    if data.generated_columns[z] and data.generated_columns[z][col] then
        return
    end

    if not data.generated_columns[z] then
        data.generated_columns[z] = {}
    end

    data.generated_columns[z][col] = true

    if not data.layers[z][col] then
        data.layers[z][col] = {}
    end

    -- Generate terrain for this column
    self.generate_terrain(self, z, col)
end

-- Generate terrain for a column
function WorldSystem.generate_terrain(self, z, col)
    local data = self.components.worlddata
    WorldGen.generate_column(data.layers, z, col, data.height)
end

-- Get block at position
function WorldSystem.get_block_id(self, z, col, row)
    if col < 0 or col >= self.components.worlddata.width or
       row < 0 or row >= self.components.worlddata.height then
        return BLOCKS.AIR
    end

    self.generate_column(self, z, col)

    if self.components.worlddata.layers[z] and
       self.components.worlddata.layers[z][col] and
       self.components.worlddata.layers[z][col][row] then
        return self.components.worlddata.layers[z][col][row]
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
    if col < 0 or col >= self.components.worlddata.width or
       row < 0 or row >= self.components.worlddata.height then
        return false
    end

    self.generate_column(self, z, col)

    if not self.components.worlddata.layers[z][col] then
        self.components.worlddata.layers[z][col] = {}
    end

    self.components.worlddata.layers[z][col][row] = block_id
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
    for row = 0, self.components.worlddata.height - 1 do
        local block_def = self.get_block_def(self, z, col, row)
        if block_def and block_def.solid then
            -- Spawn in the last air block (just above the ground)
            -- This ensures the player spawns on the surface, not inside it
            local spawn_x = col * BLOCK_SIZE + BLOCK_SIZE / 2
            local spawn_y = (row - 9) * BLOCK_SIZE + BLOCK_SIZE / 2 -- FIXME magic 9
            return spawn_x, spawn_y, z
        end
    end

    -- Default spawn at top if no ground found
    return col * BLOCK_SIZE, 0, z
end

function WorldSystem.resize(self, width, height)
    self:create_canvases()
end

return WorldSystem
