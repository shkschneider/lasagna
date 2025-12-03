local Love = require "core.love"
local Object = require "core.object"
local Registry = require "src.registries"
local BLOCKS = Registry.blocks()
local BlockRef = require "data.blocks.ids"
local Biome = require "src.data.biome"

-- Block ID offset: noise values are stored as NOISE_OFFSET + value*100
-- Block IDs 0-99 are actual blocks, 100+ are noise values
local NOISE_OFFSET = 100

-- Biome zone size in blocks (512x512 zones)
local BIOME_ZONE_SIZE = Biome.ZONE_SIZE

-- Seed offset for biome noise (set when generator loads)
local biome_seed_offset = 0

local World = Object {
    HEIGHT = 512,
    id = "world",
    priority = 10,
    generator = require("src.world.generator"),
    save = require("src.world.save"),
}

function World.load(self)
    Love.load(self)
    -- Set biome seed offset after generator loads (generator sets its seed in its load)
    biome_seed_offset = (self.generator.data.seed % 10000) + 1000
end

function World.update(self, dt)
    -- World only updates during PLAY state
    local GameState = require "src.data.gamestate"
    if G.state.current.current ~= GameState.PLAY then
        return
    end
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

    -- Draw blocks using actual block colors
    for col = start_col, end_col do
        for row = start_row, end_row do
            local value = self:get_block_value(layer, col, row)

            local x = col * BLOCK_SIZE - camera_x
            local y = row * BLOCK_SIZE - camera_y

            -- value == 0 means SKY (fully transparent, don't draw)
            if value == BlockRef.SKY then
                -- Sky is fully transparent, nothing to draw
            elseif value == BlockRef.AIR then
                -- Underground air - draw semi-transparent black
            else
                -- Draw solid blocks
                local block_id = nil

                -- Check if it's a direct block ID (< NOISE_OFFSET) or a noise value (>= NOISE_OFFSET)
                if value < NOISE_OFFSET then
                    -- Direct block ID (grass, dirt, etc.)
                    block_id = value
                else
                    -- Noise value: convert back to 0.0-1.0 range and use shared weighted lookup
                    -- Shared underground distribution prevents visible seams at biome transitions
                    local noise_value = (value - NOISE_OFFSET) / 100
                    block_id = Biome.get_underground_block(noise_value)
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

-- Get block at position (returns block ID)
-- Uses shared underground block distribution to prevent visible biome transition seams
function World.get_block_id(self, z, col, row)
    local value = self:get_block_value(z, col, row)
    -- Check if it's a direct block ID (< NOISE_OFFSET) or a noise value (>= NOISE_OFFSET)
    if value == BlockRef.SKY then
        return BlockRef.SKY
    elseif value == BlockRef.AIR then
        return BlockRef.AIR
    elseif value < NOISE_OFFSET then
        -- Direct block ID (grass, dirt, etc.)
        return value
    else
        -- Noise value: convert back to 0.0-1.0 range and use shared weighted lookup
        -- Shared underground distribution prevents visible seams at biome transitions
        local noise_value = (value - NOISE_OFFSET) / 100
        return Biome.get_underground_block(noise_value)
    end
end

-- Get block prototype at position
function World.get_block_def(self, z, col, row)
    local block_id = self.get_block_id(self, z, col, row)
    return Registry.Blocks:get(block_id)
end

-- Get biome at world position (x in world coordinates, z is layer)
-- Returns biome definition table with id, name, temperature, and humidity
-- Note: y coordinate is ignored - biomes are determined per-column, not per-block
-- This matches the terrain generator which uses zone_y = 0 for all blocks in a column
function World.get_biome(self, x, y, z)
    z = z or 0

    -- Convert world x coordinate to zone coordinate
    local zone_x = math.floor(x / BIOME_ZONE_SIZE)
    -- Use fixed zone_y = 0 to match terrain generator (biomes are column-based)
    local zone_y = 0

    -- Get temperature noise for this zone (uses biome_seed_offset for independent noise)
    -- Add z layer offset for slight variation between layers
    local temp_noise = love.math.noise(zone_x * 0.1 + z * 0.05, zone_y * 0.1, biome_seed_offset)

    -- Get humidity noise using a different seed offset (biome_seed_offset + 500)
    local humidity_noise = love.math.noise(zone_x * 0.1 + z * 0.05, zone_y * 0.1, biome_seed_offset + 500)

    -- Get biome definition from temperature and humidity
    return Biome.get_by_climate(temp_noise, humidity_noise)
end

-- Check if a position has direct access to the sky (no solid blocks above it)
-- Returns true if there's only sky from this position up to row 0 (top of world)
-- Note: This is now O(1) efficient - just check if the block is SKY (not AIR)
function World.has_access_to_sky(self, z, col, row)
    -- A block has sky access if it's SKY (0), not AIR (1) which is underground
    local value = self:get_block_value(z, col, row)
    return value == BlockRef.SKY
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
