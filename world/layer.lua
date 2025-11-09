local Object = require("lib.object")
local log = require("lib.log")
local noise = require("lib.noise")
local Blocks = require("data.blocks")

local Layer = Object {}

function Layer:new(z)
    self.z = z
    self.tiles = {}
    self.heights = {}
    self.dirt_limit = {}
    self.stone_limit = {}
    self.bedrock_heights = {}
    self.canvas = nil  -- Canvas for rendering this layer (created on first draw)
    self.dirty = true  -- Flag to indicate if canvas needs redrawing
    self.canvas_left_col = nil  -- Track which columns are rendered in canvas
    self.canvas_right_col = nil
    self.last_darken_factor = nil  -- Track darkening to detect changes
end

function Layer:update(dt) end

function Layer:mark_dirty()
    self.dirty = true
end

-- Generate terrain for a specific column
function Layer:generate_column(x, freq, base, amp)
    -- Skip if already generated
    if self.tiles[x] then return end

    -- With BLOCK_SIZE=8 instead of 16, we have 2x more columns per original column
    -- Each original block at 16px becomes a 2x2 grid of 8px blocks
    local scale = 2  -- 16 / 8 = 2

    -- Determine which original column this belongs to (1-indexed)
    -- Columns 1-2 -> original 1, columns 3-4 -> original 2, etc.
    local original_x = math.floor((x - 1) / scale) + 1

    -- Sample noise at the original column position for terrain
    local n = noise.perlin1d(original_x * freq + (self.z * 100))
    local original_top = math.max(1, math.min(C.WORLD_HEIGHT - 1, math.floor(base + amp * n)))

    -- Convert original top to new coordinate system (each original block = 2 new blocks vertically)
    -- Original top=30 means blocks 1-30 are filled, which should be new blocks 1-60
    local top = original_top * scale
    local dirt_lim = math.min(C.WORLD_HEIGHT, top + C.DIRT_THICKNESS * scale)
    
    -- Bedrock is fixed at 64 blocks below ground level (converted to new coordinate system)
    local bedrock_depth = 64 * scale  -- 128 blocks in new system
    local bedrock_level = top + bedrock_depth

    self.heights[x] = top
    self.dirt_limit[x] = dirt_lim
    self.bedrock_heights[x] = bedrock_level

    self.tiles[x] = {}
    for y = 1, C.WORLD_HEIGHT do
        local proto = nil
        -- Determine which original row this belongs to
        local original_y = math.floor((y - 1) / scale) + 1

        -- Check what block type the original position had
        if original_y == original_top then
            -- Surface: grass
            proto = Blocks and Blocks.grass
        elseif original_y > original_top and original_y <= original_top + C.DIRT_THICKNESS then
            -- Below grass: dirt layer
            proto = Blocks and Blocks.dirt
        elseif y > top + C.DIRT_THICKNESS * scale and y < bedrock_level then
            -- Below dirt until bedrock: stone
            proto = Blocks and Blocks.stone
        elseif y >= bedrock_level then
            -- At and below bedrock level: bedrock
            proto = Blocks and Blocks.bedrock
        else
            proto = nil
        end
        self.tiles[x][y] = proto
    end
    
    -- Mark layer as dirty when new terrain is generated
    self:mark_dirty()
end

-- Generate terrain for a range of x coordinates
function Layer:generate_terrain_range(x_start, x_end, freq, base, amp)
    for x = x_start, x_end do
        self:generate_column(x, freq, base, amp)
    end
end

function Layer:draw()
    local player = G:player()
    local darken_factor = 1
    
    -- Calculate darkening factor based on depth behind player
    if player and type(player.z) == "number" and self.z < player.z then
        local depth = player.z - self.z
        -- Darken by 30% per layer of depth
        darken_factor = 1 - (0.3 * depth)
        if darken_factor < 0.3 then darken_factor = 0.3 end  -- Minimum 30% brightness
    end

    -- Calculate visible columns
    local cx = G.camera:get_x()
    local cy = G.camera:get_y()
    local left_col = math.floor(cx / C.BLOCK_SIZE)
    local right_col = math.ceil((cx + G.width) / C.BLOCK_SIZE) + 1

    -- Create canvas if it doesn't exist
    if not self.canvas then
        -- Make canvas large enough to cover a reasonable area (3x screen width)
        local canvas_width = G.width * 3
        local canvas_height = C.WORLD_HEIGHT * C.BLOCK_SIZE
        self.canvas = love.graphics.newCanvas(canvas_width, canvas_height)
        self.dirty = true
        self.canvas_left_col = left_col
        self.canvas_right_col = right_col
    end

    -- Check if we need to redraw the canvas
    local needs_redraw = self.dirty
    
    -- Check if darken factor changed (player changed layers)
    if not needs_redraw and self.last_darken_factor and self.last_darken_factor ~= darken_factor then
        needs_redraw = true
    end
    
    -- Check if visible area has moved outside canvas bounds
    if not needs_redraw and self.canvas_left_col and self.canvas_right_col then
        if left_col < self.canvas_left_col or right_col > self.canvas_right_col then
            needs_redraw = true
        end
    end
    
    -- Check if any visible columns are missing (new terrain generated)
    if not needs_redraw then
        for col = left_col, right_col do
            if not self.tiles[col] then
                needs_redraw = true
                break
            end
        end
    end

    -- Redraw canvas if dirty or camera moved significantly
    if needs_redraw then
        -- Calculate which columns to draw (extend beyond visible for buffer)
        local buffer_cols = math.floor((right_col - left_col) * 1.5)
        local draw_left = left_col - buffer_cols
        local draw_right = right_col + buffer_cols
        
        self.canvas_left_col = draw_left
        self.canvas_right_col = draw_right
        
        -- Set render target to canvas
        love.graphics.setCanvas(self.canvas)
        love.graphics.clear()
        
        -- Draw all columns in range to canvas
        for col = draw_left, draw_right do
            local column = self.tiles[col]
            if column then
                for row = 1, C.WORLD_HEIGHT do
                    local proto = column[row]
                    if proto ~= nil then
                        local px = (col - 1) * C.BLOCK_SIZE
                        local py = (row - 1) * C.BLOCK_SIZE
                        -- Adjust position for canvas coordinate system
                        local canvas_x = px - (draw_left - 1) * C.BLOCK_SIZE
                        local canvas_y = py
                        if type(proto.draw) == "function" then
                            love.graphics.setColor(darken_factor, darken_factor, darken_factor, 1)
                            proto:draw(canvas_x, canvas_y, C.BLOCK_SIZE)
                        elseif proto.color and love and love.graphics then
                            local c = proto.color
                            -- Apply darkening by multiplying color components
                            love.graphics.setColor(c[1] * darken_factor, c[2] * darken_factor, c[3] * darken_factor, c[4] or 1)
                            love.graphics.rectangle("fill", canvas_x, canvas_y, C.BLOCK_SIZE, C.BLOCK_SIZE)
                        end
                    end
                end
            end
        end
        
        -- Reset render target
        love.graphics.setCanvas()
        self.dirty = false
        self.last_darken_factor = darken_factor
    end

    -- Draw the canvas to screen with full opacity (no alpha blending)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Calculate canvas offset
    local canvas_offset_x = (self.canvas_left_col - 1) * C.BLOCK_SIZE
    love.graphics.draw(self.canvas, -cx + canvas_offset_x, -cy)
    
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

return Layer
