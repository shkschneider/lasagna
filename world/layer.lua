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
    
    -- Load lighting shader if not already loaded
    if not Layer.lightingShader then
        local success, shader = pcall(love.graphics.newShader, "shaders/lighting.frag")
        if success then
            Layer.lightingShader = shader
            log.info("Lighting shader loaded successfully")
        else
            log.warn("Failed to load lighting shader: " .. tostring(shader))
            Layer.lightingShader = nil
        end
    end
    
    -- Canvas for layer and block rendering (created on first draw or resize)
    self.layerCanvas = nil
    self.blockCanvas = nil
end

function Layer:update(dt) end

-- Generate terrain for a specific column
function Layer:generate_column(x, freq, base, amp)
    -- Skip if already generated
    if self.tiles[x] then return end

    local n = noise.perlin1d(x * freq + (self.z * 100))
    local top = math.max(1, math.min(C.WORLD_HEIGHT - 1, math.floor(base + amp * n)))
    local dirt_lim = math.min(C.WORLD_HEIGHT, top + C.DIRT_THICKNESS)
    local stone_lim = math.min(C.WORLD_HEIGHT, top + C.DIRT_THICKNESS + C.STONE_THICKNESS)

    self.heights[x] = top
    self.dirt_limit[x] = dirt_lim
    self.stone_limit[x] = stone_lim

    self.tiles[x] = {}
    for y = 1, C.WORLD_HEIGHT do
        local proto = nil
        if y == top then
            proto = Blocks and Blocks.grass
        elseif y > top and y <= dirt_lim then
            proto = Blocks and Blocks.dirt
        elseif y > dirt_lim and y <= stone_lim then
            proto = Blocks and Blocks.stone
        else
            proto = nil
        end
        self.tiles[x][y] = proto
    end
end

-- Generate terrain for a range of x coordinates
function Layer:generate_terrain_range(x_start, x_end, freq, base, amp)
    for x = x_start, x_end do
        self:generate_column(x, freq, base, amp)
    end
end

function Layer:draw()
    local alpha = 1
    local player = G:player()
    if player and type(player.z) == "number" and self.z < player.z then
        local depth = player.z - self.z
        alpha = 1 - 0.25 * depth
        if alpha < 0 then alpha = 0 end
    end

    -- Calculate visible columns
    local cx = G.camera:get_x()
    local left_col = math.floor(cx / C.BLOCK_SIZE)
    local right_col = math.ceil((cx + G.width) / C.BLOCK_SIZE) + 1

    -- Only apply lighting shader to the player's current layer
    local applyLighting = (Layer.lightingShader and self.z == player.z)
    
    -- Draw the layer directly to screen first
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(-cx, 0)

    -- Draw visible columns
    for col = left_col, right_col do
        local column = self.tiles[col]
        if column then
            for row = 1, C.WORLD_HEIGHT do
                local proto = column[row]
                if proto ~= nil then
                    local px = (col - 1) * C.BLOCK_SIZE
                    local py = (row - 1) * C.BLOCK_SIZE
                    if type(proto.draw) == "function" then
                        love.graphics.setColor(1, 1, 1, alpha)
                        proto:draw(px, py, C.BLOCK_SIZE)
                    elseif proto.color and love and love.graphics then
                        local c = proto.color
                        love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * alpha)
                        love.graphics.rectangle("fill", px, py, C.BLOCK_SIZE, C.BLOCK_SIZE)
                    end
                end
            end
        end
    end

    love.graphics.pop()
    
    -- Apply lighting as a multiplicative overlay
    if applyLighting then
        -- Create canvases if needed
        local w, h = G.width, G.height
        if not self.lightCanvas or self.lightCanvas:getWidth() ~= w or self.lightCanvas:getHeight() ~= h then
            self.lightCanvas = love.graphics.newCanvas(w, h)
            self.blockCanvas = love.graphics.newCanvas(w, h)
        end
        
        -- Render block solidity map
        love.graphics.setCanvas(self.blockCanvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.push()
        love.graphics.origin()
        love.graphics.translate(-cx, 0)
        
        for col = left_col, right_col do
            local column = self.tiles[col]
            if column then
                for row = 1, C.WORLD_HEIGHT do
                    local proto = column[row]
                    if proto ~= nil then
                        local px = (col - 1) * C.BLOCK_SIZE
                        local py = (row - 1) * C.BLOCK_SIZE
                        love.graphics.setColor(1, 1, 1, 1)
                        love.graphics.rectangle("fill", px, py, C.BLOCK_SIZE, C.BLOCK_SIZE)
                    end
                end
            end
        end
        
        love.graphics.pop()
        love.graphics.setCanvas()
        
        -- Render light map using shader
        love.graphics.setCanvas(self.lightCanvas)
        love.graphics.clear(C.AMBIENT_LIGHT, C.AMBIENT_LIGHT, C.AMBIENT_LIGHT, 1)
        
        -- Calculate player position in screen coordinates
        local playerScreenX = (player.px - 1 + player.width / 2) * C.BLOCK_SIZE - cx
        local playerScreenY = (player.py - 1 + player.height / 2) * C.BLOCK_SIZE
        
        -- Set shader uniforms
        Layer.lightingShader:send("lightPos", {playerScreenX, playerScreenY})
        Layer.lightingShader:send("screenSize", {G.width, G.height})
        Layer.lightingShader:send("lightRadius", C.LIGHT_RADIUS)
        Layer.lightingShader:send("raycastStepSize", C.RAYCAST_STEP_SIZE)
        Layer.lightingShader:send("blockTexture", self.blockCanvas)
        
        -- Draw a full-screen quad with the light shader
        love.graphics.setShader(Layer.lightingShader)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, G.width, G.height)
        love.graphics.setShader()
        
        love.graphics.setCanvas()
        
        -- Multiply light map over the scene
        love.graphics.setBlendMode("multiply", "premultiplied")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.lightCanvas, 0, 0)
        love.graphics.setBlendMode("alpha")
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

return Layer
