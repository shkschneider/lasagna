local Object = require("lib.object")
local Gravity = require("entities.components.gravity")

local Rocket = Object {}

function Rocket:new(px, py, z, vx, vy)
    self.px = px        -- Position in world coordinates (blocks)
    self.py = py
    self.z = z          -- Layer
    self.vx = vx or 0   -- Velocity in blocks per second
    self.vy = vy or 0
    self.width = 0.5    -- Larger size (half block)
    self.height = 0.5
    self.lifetime = 0   -- Tracks how long the rocket has existed
    self.max_lifetime = 10  -- Rockets despawn after 10 seconds
    self.color = {1, 0.5, 0, 1}  -- Orange
    self.gravity = Gravity(self)  -- Rockets are affected by gravity
end

function Rocket:update(dt, world, player)
    self.lifetime = self.lifetime + dt

    -- Check if should despawn
    if self.lifetime >= self.max_lifetime then
        return false  -- Signal to world that this entity should be removed
    end

    -- Apply gravity
    self.gravity:update(dt)

    -- Move the rocket
    local dx = self.vx * dt
    local dy = self.vy * dt
    
    -- Check for collision with blocks before moving
    local next_px = self.px + dx
    local next_py = self.py + dy
    
    -- Get the block at the rocket's next position
    local col = math.floor(next_px + self.width / 2)
    local row = math.floor(next_py + self.height / 2)
    
    if row >= 1 and row <= C.WORLD_HEIGHT then
        local block_type = world:get_block_type(self.z, col, row)
        
        -- Check if we hit a solid block
        if block_type and block_type ~= "air" and block_type ~= "out" then
            -- Hit a block - explode in a star pattern
            self:explode(world, col, row)
            
            -- Remove the rocket
            return false
        end
    end
    
    -- No collision, move the rocket
    self.px = next_px
    self.py = next_py
    
    return true  -- Keep this entity alive
end

function Rocket:explode(world, center_col, center_row)
    -- Star pattern: center + 4 cardinal directions + 4 diagonals
    local star_pattern = {
        {0, 0},   -- Center
        {-1, 0},  -- Left
        {1, 0},   -- Right
        {0, -1},  -- Up
        {0, 1},   -- Down
        {-1, -1}, -- Top-left diagonal
        {1, -1},  -- Top-right diagonal
        {-1, 1},  -- Bottom-left diagonal
        {1, 1},   -- Bottom-right diagonal
    }
    
    -- Destroy blocks in star pattern
    for _, offset in ipairs(star_pattern) do
        local col = center_col + offset[1]
        local row = center_row + offset[2]
        
        if row >= 1 and row <= C.WORLD_HEIGHT then
            local block_type = world:get_block_type(self.z, col, row)
            
            if block_type and block_type ~= "air" and block_type ~= "out" then
                if type(block_type) == "table" then
                    -- Store the block type before removing it
                    local block_proto = block_type
                    
                    -- Remove the block
                    local ok, msg = world:set_block(self.z, col, row, nil)
                    if not ok then
                        world:set_block(self.z, col, row, "__empty")
                    end
                    
                    -- Drop the block at its center position
                    if ok and block_proto and block_proto ~= "air" and block_proto ~= "out" then
                        if type(block_proto.drop) == "function" then
                            block_proto:drop(world, col, row, self.z, 1)
                        end
                    end
                end
            end
        end
    end
end

function Rocket:draw()
    -- Position is already in 1-indexed world coordinates
    -- Drawing needs to convert to screen pixels
    local cx = G.camera:get_x()
    local cy = G.camera:get_y()
    local sx = (self.px - 1) * C.BLOCK_SIZE - cx
    local sy = (self.py - 1) * C.BLOCK_SIZE - cy

    -- Draw the rocket as an orange rectangle
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4] or 1)
    love.graphics.rectangle("fill", sx, sy, self.width * C.BLOCK_SIZE, self.height * C.BLOCK_SIZE, 1, 1)

    love.graphics.setColor(1, 1, 1, 1)
end

return Rocket
