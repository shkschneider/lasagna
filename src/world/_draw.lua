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

-- Draw only the outlines of blocks that are touching air
local function draw_outlines(self, layer)
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

    -- Draw block outlines where they touch air
    for col = start_col, end_col do
        for row = start_row, end_row do
            local value = self:get_block_value(layer, col, row)

            -- Skip air and sky blocks
            if not is_air_or_sky(value) then
                local x = col * BLOCK_SIZE - camera_x
                local y = row * BLOCK_SIZE - camera_y

                -- Get block color
                local block_id = nil
                if value < self.NOISE_OFFSET then
                    block_id = value
                else
                    local noise_value = (value - self.NOISE_OFFSET) / 100
                    block_id = Biome.get_underground_block(noise_value)
                end

                if block_id then
                    local block = Registry.Blocks:get(block_id)
                    if block and block.color then
                        love.graphics.setColor(block.color[1], block.color[2], block.color[3], block.color[4] or 1)

                        -- Check all 4 neighbors and draw lines for edges touching air
                        local top = self:get_block_value(layer, col, row - 1)
                        local bottom = self:get_block_value(layer, col, row + 1)
                        local left = self:get_block_value(layer, col - 1, row)
                        local right = self:get_block_value(layer, col + 1, row)

                        -- Draw top edge if top neighbor is air
                        if is_air_or_sky(top) then
                            love.graphics.line(x, y, x + BLOCK_SIZE, y)
                        end

                        -- Draw bottom edge if bottom neighbor is air
                        if is_air_or_sky(bottom) then
                            love.graphics.line(x, y + BLOCK_SIZE, x + BLOCK_SIZE, y + BLOCK_SIZE)
                        end

                        -- Draw left edge if left neighbor is air
                        if is_air_or_sky(left) then
                            love.graphics.line(x, y, x, y + BLOCK_SIZE)
                        end

                        -- Draw right edge if right neighbor is air
                        if is_air_or_sky(right) then
                            love.graphics.line(x + BLOCK_SIZE, y, x + BLOCK_SIZE, y + BLOCK_SIZE)
                        end
                    end
                end
            end
        end
    end
end

function World.draw3(self, pz)
    for z = pz + 1, LAYER_MAX do
        draw_outlines(self, z)
    end
end
