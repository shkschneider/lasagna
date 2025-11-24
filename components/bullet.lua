-- Bullet Component
-- Self-contained bullet entity with update and draw logic

require "lib"

local Object = require "core.object"
local Position = require "components.position"
local Velocity = require "components.velocity"
local Physics = require "components.physics"
local Registry = require "registries"

local BLOCKS = Registry.blocks()

local Bullet = {}

function Bullet.new(damage, lifetime, width, height, color, destroys_blocks)
    local bullet = {
        damage = damage or 10,
        lifetime = lifetime or 5,
        width = width or 2,
        height = height or 2,
        color = color or {1, 1, 0, 1},
        destroys_blocks = destroys_blocks or false,
    }
    return bullet
end

-- Create a complete bullet entity
function Bullet.create_entity(x, y, layer, vx, vy, width, height, color, gravity, destroys_blocks)
    local entity = Object.new {
        id = uuid(),
        priority = 65,
        position = Position.new(x, y, layer),
        velocity = Velocity.new(vx, vy),
        physics = Physics.new(gravity, 1.0),
        bullet = Bullet.new(10, 5, width, height, color, destroys_blocks),
    }
    
    -- Add update method to entity
    function entity.update(self, dt)
        -- Apply physics (gravity)
        if self.physics then
            self.velocity.vy = self.velocity.vy + self.physics.gravity * dt
        end
        
        -- Update position
        self.position.x = self.position.x + self.velocity.vx * dt
        self.position.y = self.position.y + self.velocity.vy * dt
        
        -- Decrease lifetime
        self.bullet.lifetime = self.bullet.lifetime - dt
        
        -- Check for removal
        if self.bullet.lifetime <= 0 then
            self.remove_me = true
            return
        end
        
        -- Check collision with blocks
        local col, row = G.world:world_to_block(self.position.x, self.position.y)
        local block_def = G.world:get_block_def(self.position.z, col, row)
        
        if block_def and block_def.solid then
            -- Bullet hit a block
            
            -- If this bullet destroys blocks, destroy it and spawn drop
            if self.bullet.destroys_blocks then
                local block_id = G.world:get_block_id(self.position.z, col, row)
                local proto = Registry.Blocks:get(block_id)
                
                if proto then
                    -- Remove block
                    G.world:set_block(self.position.z, col, row, BLOCKS.AIR)
                    
                    -- Spawn drop
                    if proto.drops then
                        local drop_id, drop_count = proto.drops()
                        if drop_id then
                            local wx, wy = G.world:block_to_world(col, row)
                            G.drop:create_drop(
                                wx + BLOCK_SIZE / 2,
                                wy + BLOCK_SIZE / 2,
                                self.position.z,
                                drop_id,
                                drop_count
                            )
                        end
                    end
                end
            end
            
            -- Mark for removal
            self.remove_me = true
        end
    end
    
    -- Add draw method to entity
    function entity.draw(self)
        local camera_x, camera_y = G.camera:get_offset()
        local x = self.position.x - camera_x - self.bullet.width / 2
        local y = self.position.y - camera_y - self.bullet.height / 2
        
        love.graphics.setColor(self.bullet.color)
        love.graphics.rectangle("fill", x, y, self.bullet.width, self.bullet.height)
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    return entity
end

return Bullet
