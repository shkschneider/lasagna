local Object = require("lib.object")
local Physics = require("world.physics")

local Bullet = Object {}

function Bullet:new(px, py, z, vx, vy)
    self.px = px        -- Position in world coordinates (blocks)
    self.py = py
    self.z = z          -- Layer
    self.vx = vx or 0   -- Velocity in blocks per second
    self.vy = vy or 0
    self.width = 0.25   -- Small size (quarter block)
    self.height = 0.25
    self.lifetime = 0   -- Tracks how long the bullet has existed
    self.max_lifetime = 5  -- Bullets despawn after 5 seconds
    self.color = {1, 1, 0, 1}  -- Yellow
end

function Bullet:update(dt, world, player)
    self.lifetime = self.lifetime + dt

    -- Check if should despawn
    if self.lifetime >= self.max_lifetime then
        return false  -- Signal to world that this entity should be removed
    end

    -- Move the bullet
    local dx = self.vx * dt
    local dy = self.vy * dt
    
    -- Check for collision with blocks before moving
    local next_px = self.px + dx
    local next_py = self.py + dy
    
    -- Get the block at the bullet's next position
    local col = math.floor(next_px + self.width / 2)
    local row = math.floor(next_py + self.height / 2)
    
    if row >= 1 and row <= C.WORLD_HEIGHT then
        local block_type = world:get_block_type(self.z, col, row)
        
        -- Check if we hit a solid block
        if block_type and block_type ~= "air" and block_type ~= "out" then
            -- Hit a block - destroy it and spawn drop
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
            
            -- Remove the bullet
            return false
        end
    end
    
    -- No collision, move the bullet
    self.px = next_px
    self.py = next_py
    
    return true  -- Keep this entity alive
end

function Bullet:draw()
    -- Position is already in 1-indexed world coordinates
    -- Drawing needs to convert to screen pixels
    local cx = G.camera:get_x()
    local cy = G.camera:get_y()
    local sx = (self.px - 1) * C.BLOCK_SIZE - cx
    local sy = (self.py - 1) * C.BLOCK_SIZE - cy

    -- Draw the bullet as a small yellow rectangle
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4] or 1)
    love.graphics.rectangle("fill", sx, sy, self.width * C.BLOCK_SIZE, self.height * C.BLOCK_SIZE, 1, 1)

    love.graphics.setColor(1, 1, 1, 1)
end

return Bullet
