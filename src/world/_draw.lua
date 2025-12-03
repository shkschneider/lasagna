local Registry = require "src.game.registries"
local BlockRef = require "data.blocks.ids"
local Biome = require "src.world.biome"

local function draw(self, layer)
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
                if value < self.NOISE_OFFSET then
                    -- Direct block ID (grass, dirt, etc.)
                    block_id = value
                else
                    -- Noise value: convert back to 0.0-1.0 range and use shared weighted lookup
                    -- Shared underground distribution prevents visible seams at biome transitions
                    local noise_value = (value - self.NOISE_OFFSET) / 100
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

function World.draw(self) end

function World.draw1(self, pz)
    for z = LAYER_MIN, pz - 1 do
        draw(self, z)
    end
end

function World.draw2(self, pz)
    draw(self, pz)
end

-- Helper function to check if a block is air or sky (transparent)
local function is_air_or_sky(value)
    return value == BlockRef.SKY or value == BlockRef.AIR
end

-- Draw with conditional transparency based on player position
local function draw_with_transparency(self, layer, pz)
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

    -- Check if player is behind a block on this layer
    local player_x, player_y, player_z = G.player:get_position()
    local player_col = math.floor(player_x / BLOCK_SIZE)
    local player_row = math.floor(player_y / BLOCK_SIZE)
    local player_value = self:get_block_value(layer, player_col, player_row)
    local player_behind_block = not is_air_or_sky(player_value)

    -- Determine transparency: 0.5 if player is behind a block on this layer, 1.0 otherwise
    local transparency = player_behind_block and 0.5 or 1.0

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
                if value < self.NOISE_OFFSET then
                    -- Direct block ID (grass, dirt, etc.)
                    block_id = value
                else
                    -- Noise value: convert back to 0.0-1.0 range and use shared weighted lookup
                    -- Shared underground distribution prevents visible seams at biome transitions
                    local noise_value = (value - self.NOISE_OFFSET) / 100
                    block_id = Biome.get_underground_block(noise_value)
                end

                if block_id then
                    local block = Registry.Blocks:get(block_id)
                    if block and block.color then
                        -- Apply transparency multiplier
                        local alpha = (block.color[4] or 1) * transparency
                        love.graphics.setColor(block.color[1], block.color[2], block.color[3], alpha)
                        love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)
                    end
                end
            end
        end
    end
end

function World.draw3(self, pz)
    for z = pz + 1, LAYER_MAX do
        draw_with_transparency(self, z, pz)
    end
end
