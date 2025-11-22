-- World System
-- Manages world generation, block storage, and world queries

local log = require "lib.log"
local WorldData = require("components.worlddata")
local Registry = require("registries.init")
local BLOCK_IDS = Registry.block_ids()
local BlocksRegistry = Registry.blocks()
local noise = require("lib.noise")

local WorldSystem = {
    id = "world",
    priority = 10,
    components = {},
    BLOCK_SIZE = 16,
    WIDTH = 512,
    HEIGHT = 128,
}

function WorldSystem.load(self, seed)
    log.info("World:", seed)

    -- Initialize components
    self.components.worlddata = WorldData.new(seed, self.WIDTH, self.HEIGHT)

    -- Seed the noise library
    noise.seed(self.components.worlddata.seed)
end

function WorldSystem.update(self, dt)
    -- World generation happens on-demand in get_block
end

function WorldSystem.draw(self)
    -- World rendering is handled by RenderSystem
end

-- Generate a column if not already generated
function WorldSystem.generate_column(self, layer, col)
    local data = self.components.worlddata

    if data.generated_columns[layer] and data.generated_columns[layer][col] then
        return
    end

    if not data.generated_columns[layer] then
        data.generated_columns[layer] = {}
    end

    data.generated_columns[layer][col] = true

    if not data.layers[layer][col] then
        data.layers[layer][col] = {}
    end

    -- Generate terrain for this column
    self.generate_terrain(self, layer, col)
end

-- Generate terrain for a column (simplified from world.lua)
function WorldSystem.generate_terrain(self, layer, col)
    local data = self.components.worlddata

    -- Base terrain height
    local BASE_HEIGHT = 0.6
    local BASE_FREQUENCY = 0.02
    local BASE_AMPLITUDE = 15

    local noise_val = noise.octave_perlin2d(col * BASE_FREQUENCY, layer * 0.1, 4, 0.5, 2.0)
    local base_height = math.floor(data.height * BASE_HEIGHT + noise_val * BASE_AMPLITUDE)

    -- Layer-specific height adjustments
    if layer == 1 then
        base_height = base_height - 5
    elseif layer == -1 then
        base_height = base_height + 5
    end

    -- Fill terrain
    for row = 0, data.height - 1 do
        if row >= base_height then
            -- Underground - stone
            data.layers[layer][col][row] = BLOCK_IDS.STONE
        else
            -- Above ground - air
            data.layers[layer][col][row] = BLOCK_IDS.AIR
        end
    end

    -- Add dirt layer
    local DIRT_MIN_DEPTH = 5
    local DIRT_MAX_DEPTH = 15
    local dirt_depth = DIRT_MIN_DEPTH + math.floor((DIRT_MAX_DEPTH - DIRT_MIN_DEPTH) *
        (noise.perlin2d(col * 0.05, layer * 0.1) + 1) / 2)

    for row = base_height, math.min(base_height + dirt_depth - 1, data.height - 1) do
        if data.layers[layer][col][row] == BLOCK_IDS.STONE then
            data.layers[layer][col][row] = BLOCK_IDS.DIRT
        end
    end

    -- Grass on surface dirt exposed to air
    if base_height > 0 and base_height < data.height then
        if data.layers[layer][col][base_height] == BLOCK_IDS.DIRT and
           data.layers[layer][col][base_height - 1] == BLOCK_IDS.AIR then
            data.layers[layer][col][base_height] = BLOCK_IDS.GRASS
        end
    end
end

-- Get block at position
function WorldSystem.get_block(self, layer, col, row)
    if col < 0 or col >= self.components.worlddata.width or
       row < 0 or row >= self.components.worlddata.height then
        return BLOCK_IDS.AIR
    end

    self.generate_column(self, layer, col)

    if self.components.worlddata.layers[layer] and
       self.components.worlddata.layers[layer][col] and
       self.components.worlddata.layers[layer][col][row] then
        return self.components.worlddata.layers[layer][col][row]
    end

    return BLOCK_IDS.AIR
end

-- Get block prototype at position
function WorldSystem.get_block_proto(self, layer, col, row)
    local block_id = self.get_block(self, layer, col, row)
    return BlocksRegistry:get(block_id)
end

-- Set block at position
function WorldSystem.set_block(self, layer, col, row, block_id)
    if col < 0 or col >= self.components.worlddata.width or
       row < 0 or row >= self.components.worlddata.height then
        return false
    end

    self.generate_column(self, layer, col)

    if not self.components.worlddata.layers[layer][col] then
        self.components.worlddata.layers[layer][col] = {}
    end

    self.components.worlddata.layers[layer][col][row] = block_id
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
function WorldSystem.find_spawn_position(self, start_col, start_layer)
    local col = start_col
    local layer = start_layer or 0

    -- Find ground
    for row = 0, self.components.worlddata.height - 1 do
        local block_proto = self.get_block_proto(self, layer, col, row)
        if block_proto and block_proto.solid then
            -- Found ground, spawn 2 blocks above
            local spawn_x = col * self.BLOCK_SIZE + self.BLOCK_SIZE / 2
            local spawn_y = (row - 2) * self.BLOCK_SIZE + self.BLOCK_SIZE
            return spawn_x, spawn_y, layer
        end
    end

    -- Default spawn
    return col * self.BLOCK_SIZE, 0, layer
end

return WorldSystem
