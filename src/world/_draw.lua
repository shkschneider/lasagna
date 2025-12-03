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

-- Local Cutout Mask + Depth-peel Ranking approach
-- Parameters
local CUTOUT_RADIUS = 64  -- pixels, player torso zone
local CUTOUT_FEATHER = 12  -- pixels, soft edge blur
local DEPTH_PEEL_K = 3  -- capture nearest 3 foreground layers
local OUTLINE_ALPHA = 0.9  -- outline opacity for rank 1
local OUTLINE_WIDTH = 2  -- outline line width in pixels
local FADE_ALPHA = 0.35  -- fade opacity for rank 2

local function draw_cutout_with_ranking(self, layer, pz)
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
    
    -- Get player position
    local player_x, player_y, player_z = G.player:get_position()
    
    -- Determine depth rank for this layer (distance from player layer)
    local depth_rank = layer - player_z  -- rank 0 = same layer, rank 1 = one layer above, etc.
    
    -- Draw blocks using actual block colors with ranking treatment
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
                        -- Calculate distance from block center to player center
                        local block_center_x = col * BLOCK_SIZE + BLOCK_SIZE / 2
                        local block_center_y = row * BLOCK_SIZE + BLOCK_SIZE / 2
                        local dx = block_center_x - player_x
                        local dy = block_center_y - player_y
                        local dist = math.sqrt(dx * dx + dy * dy)
                        
                        -- Determine treatment based on cutout and depth rank
                        local in_cutout_core = dist < CUTOUT_RADIUS
                        local in_cutout_feather = dist >= CUTOUT_RADIUS and dist < (CUTOUT_RADIUS + CUTOUT_FEATHER)
                        
                        -- Apply cutout with feathering
                        local cutout_alpha = 1.0
                        if in_cutout_core then
                            cutout_alpha = 0.0  -- Hidden in core
                        elseif in_cutout_feather then
                            -- Smooth feather from 0 to 1
                            local feather_t = (dist - CUTOUT_RADIUS) / CUTOUT_FEATHER
                            cutout_alpha = feather_t
                        end
                        
                        -- Apply depth-peel ranking treatment
                        local rank_alpha = 1.0
                        local draw_outline = false
                        
                        if depth_rank >= DEPTH_PEEL_K then
                            -- Rank 3+: hidden
                            rank_alpha = 0.0
                        elseif depth_rank == (DEPTH_PEEL_K - 1) then
                            -- Rank 2: faded
                            rank_alpha = FADE_ALPHA
                        elseif depth_rank == (DEPTH_PEEL_K - 2) then
                            -- Rank 1: outline only
                            draw_outline = true
                            rank_alpha = 0.0  -- Don't draw fill for outline-only
                        end
                        -- depth_rank == 0: normal rendering (rank_alpha = 1.0)
                        
                        -- Combine cutout and rank alpha
                        local final_alpha = cutout_alpha * rank_alpha * (block.color[4] or 1)
                        
                        -- Draw block fill (if not outline-only mode)
                        if final_alpha > 0.01 then
                            love.graphics.setColor(block.color[1], block.color[2], block.color[3], final_alpha)
                            love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)
                        end
                        
                        -- Draw outline for rank 1
                        if draw_outline and cutout_alpha > 0.01 then
                            local outline_alpha = OUTLINE_ALPHA * cutout_alpha
                            love.graphics.setColor(block.color[1], block.color[2], block.color[3], outline_alpha)
                            love.graphics.setLineWidth(OUTLINE_WIDTH)
                            love.graphics.rectangle("line", x, y, BLOCK_SIZE, BLOCK_SIZE)
                            love.graphics.setLineWidth(1)  -- Reset line width
                        end
                    end
                end
            end
        end
    end
end

function World.draw3(self, pz)
    for z = pz + 1, LAYER_MAX do
        draw_cutout_with_ranking(self, z, pz)
    end
end
