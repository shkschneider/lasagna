-- World System
-- Manages world generation, block storage, and world queries

local log = require "lib.log"
local noise = require "lib.noise"

local Systems = require "systems"
local WorldData = require "components.worlddata"
local Registry = require "registries"

local BLOCKS = Registry.blocks()

local WorldSystem = {
    id = "world",
    priority = 10,
    components = {},
    BLOCK_SIZE = 16,
    WIDTH = 512,
    HEIGHT = 128,
    canvases = {},
}

function WorldSystem.load(self, seed)
    -- Initialize components
    self.components.worlddata = WorldData.new(seed, self.WIDTH, self.HEIGHT)
    log.info("World:", self.components.worlddata.seed)

    -- Seed the noise library
    noise.seed(self.components.worlddata.seed)

    -- Create canvases for layer rendering
    self:create_canvases()
end

function WorldSystem.create_canvases(self)
    self.screen_width, self.screen_height = love.graphics.getDimensions()

    -- Create canvases for each layer
    self.canvases[-1] = love.graphics.newCanvas(self.screen_width, self.screen_height)
    self.canvases[0] = love.graphics.newCanvas(self.screen_width, self.screen_height)
    self.canvases[1] = love.graphics.newCanvas(self.screen_width, self.screen_height)
end

function WorldSystem.update(self, dt)
    -- World generation happens on-demand in get_block
end

function WorldSystem.draw(self)
    local player = Systems.get("player")
    local camera = Systems.get("camera")

    if not player or not camera then
        return
    end

    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()

    -- Recreate canvases if screen size changed
    if not self.screen_width or not self.screen_height or
       self.screen_width ~= screen_width or self.screen_height ~= screen_height then
        self.screen_width = screen_width
        self.screen_height = screen_height
        self:create_canvases()
    end

    local camera_x, camera_y = camera:get_offset()
    local player_x, player_y, player_z = player:get_position()

    -- Clear screen with sky blue background
    love.graphics.clear(0.4, 0.6, 0.9, 1)

    -- Calculate visible area
    local start_col = math.floor(camera_x / self.BLOCK_SIZE) - 1
    local end_col = math.ceil((camera_x + screen_width) / self.BLOCK_SIZE) + 1
    local start_row = math.floor(camera_y / self.BLOCK_SIZE) - 1
    local end_row = math.ceil((camera_y + screen_height) / self.BLOCK_SIZE) + 1

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
                        local x = col * self.BLOCK_SIZE - camera_x
                        local y = row * self.BLOCK_SIZE - camera_y
                        love.graphics.rectangle("fill", x, y, self.BLOCK_SIZE, self.BLOCK_SIZE)
                    end
                end
            end

            love.graphics.setCanvas()
        end
    end

    -- Composite layers to screen
    -- Set blend mode to ensure proper layering (solid blocks should completely cover layers below)
    love.graphics.setBlendMode("alpha", "premultiplied")

    -- Draw back layer (dimmed)
    if self.canvases[-1] then
        if player_z == -1 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5) -- Dimmed
        end
        love.graphics.draw(self.canvases[-1], 0, 0)
    end

    -- Draw main layer
    if self.canvases[0] then
        if player_z == 0 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5) -- Dimmed
        end
        love.graphics.draw(self.canvases[0], 0, 0)
    end

    -- Draw front layer (semi-transparent)
    if self.canvases[1] then
        if player_z == 1 then
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(0.33, 0.33, 0.33, 0.33) -- Very dimmed
        end
        love.graphics.draw(self.canvases[1], 0, 0)
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

-- Generate terrain for a column (simplified from world.lua)
function WorldSystem.generate_terrain(self, z, col)
    local data = self.components.worlddata

    -- Base terrain height
    local BASE_HEIGHT = 0.6
    local BASE_FREQUENCY = 0.02
    local BASE_AMPLITUDE = 15

    local noise_val = noise.octave_perlin2d(col * BASE_FREQUENCY, z * 0.1, 4, 0.5, 2.0)
    local base_height = math.floor(data.height * BASE_HEIGHT + noise_val * BASE_AMPLITUDE)

    -- Layer-specific height adjustments
    if z == 1 then
        base_height = base_height + 2
    elseif z == -1 then
        base_height = base_height - 2
    end

    -- Fill terrain
    for row = 0, data.height - 1 do
        if row >= base_height then
            -- Underground - stone
            data.layers[z][col][row] = BLOCKS.STONE
        else
            -- Above ground - air
            data.layers[z][col][row] = BLOCKS.AIR
        end
    end

    -- Add dirt z
    local DIRT_MIN_DEPTH = 5
    local DIRT_MAX_DEPTH = 15
    local dirt_depth = DIRT_MIN_DEPTH + math.floor((DIRT_MAX_DEPTH - DIRT_MIN_DEPTH) *
        (noise.perlin2d(col * 0.05, z * 0.1) + 1) / 2)

    for row = base_height, math.min(base_height + dirt_depth - 1, data.height - 1) do
        if data.layers[z][col][row] == BLOCKS.STONE then
            data.layers[z][col][row] = BLOCKS.DIRT
        end
    end

    -- Grass on surface dirt exposed to air
    if base_height > 0 and base_height < data.height then
        if data.layers[z][col][base_height] == BLOCKS.DIRT and
           data.layers[z][col][base_height - 1] == BLOCKS.AIR then
            data.layers[z][col][base_height] = BLOCKS.GRASS
        end
    end
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
    return math.floor(world_x / self.BLOCK_SIZE), math.floor(world_y / self.BLOCK_SIZE)
end

-- Block to world coordinate conversion
function WorldSystem.block_to_world(self, col, row)
    return col * self.BLOCK_SIZE, row * self.BLOCK_SIZE
end

-- Find spawn position (simplified)
function WorldSystem.find_spawn_position(self, start_col, start_z)
    local col = start_col
    local z = start_z or 0

    -- Find ground
    for row = 0, self.components.worlddata.height - 1 do
        local block_def = self.get_block_def(self, z, col, row)
        if block_def and block_def.solid then
            -- Found ground, spawn 2 blocks above
            local spawn_x = col * self.BLOCK_SIZE + self.BLOCK_SIZE / 2
            local spawn_y = (row - 2) * self.BLOCK_SIZE + self.BLOCK_SIZE
            return spawn_x, spawn_y, z
        end
    end

    -- Default spawn
    return col * self.BLOCK_SIZE, 0, z
end

function WorldSystem.resize(self, width, height)
    self.screen_width = width
    self.screen_height = height
    self:create_canvases()
end

return WorldSystem
