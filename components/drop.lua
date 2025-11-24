-- Drop Component
-- Self-contained drop entity with update and draw logic

require "lib"

local Object = require "core.object"
local Position = require "components.position"
local Velocity = require "components.velocity"
local Physics = require "components.physics"
local Registry = require "registries"

local MERGING_ENABLED = false

local Drop = {}

function Drop.new(block_id, count, lifetime, pickup_delay)
    return {
        block_id = block_id,
        count = count or 1,
        lifetime = lifetime or 300,
        pickup_delay = pickup_delay or 0.5,
    }
end

-- Create a complete drop entity
function Drop.create_entity(x, y, layer, block_id, count)
    local entity = Object.new {
        id = uuid(),
        priority = 70,
        position = Position.new(x, y, layer),
        velocity = Velocity.new((math.random() - 0.5) * 50, -50),
        physics = Physics.new(400, 0.8),
        drop = Drop.new(block_id, count, 300, 0.5),
    }
    
    -- Add update method to entity
    function entity.update(self, dt)
        -- Physics
        self.velocity.vy = self.velocity.vy + self.physics.gravity * dt
        self.position.x = self.position.x + self.velocity.vx * dt
        self.position.y = self.position.y + self.velocity.vy * dt
        
        -- Check collision with ground
        local drop_height = BLOCK_SIZE / 2
        local col, row = G.world:world_to_block(
            self.position.x,
            self.position.y + drop_height / 2
        )
        local block_def = G.world:get_block_def(self.position.z, col, row)
        
        local on_ground = false
        if block_def and block_def.solid then
            self.velocity.vy = 0
            -- Position drop so its bottom edge rests on top of the block
            self.position.y = row * BLOCK_SIZE - drop_height / 2
            on_ground = true
        end
        
        -- Apply friction only when on ground
        if on_ground then
            self.velocity.vx = self.velocity.vx * self.physics.friction
        end
        
        -- Decrease pickup delay
        if self.drop.pickup_delay > 0 then
            self.drop.pickup_delay = self.drop.pickup_delay - dt
        end
        
        -- Check pickup by player
        local PICKUP_RANGE = BLOCK_SIZE
        if self.drop.pickup_delay <= 0 then
            local player_x, player_y, player_z = G.player:get_position()
            if self.position.z == player_z then
                local dx = self.position.x - player_x
                local dy = self.position.y - player_y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                if dist < PICKUP_RANGE then
                    -- Try to add to player inventory
                    if G.player:add_to_inventory(self.drop.block_id, self.drop.count) then
                        -- Successfully picked up
                        self.remove_me = true
                        return
                    end
                end
            end
        end
        
        -- Lifetime
        self.drop.lifetime = self.drop.lifetime - dt
        if self.drop.lifetime <= 0 then
            self.remove_me = true
        end
    end
    
    -- Add draw method to entity
    function entity.draw(self)
        local camera_x, camera_y = G.camera:get_offset()
        local proto = Registry.Blocks:get(self.drop.block_id)
        
        if proto then
            -- Drop is 1/2 width and 1/2 height
            local width = BLOCK_SIZE / 2
            local height = BLOCK_SIZE / 2
            local x = self.position.x - camera_x - width / 2
            local y = self.position.y - camera_y - height / 2
            
            -- Draw the colored block
            love.graphics.setColor(proto.color)
            love.graphics.rectangle("fill", x, y, width, height)
            
            if MERGING_ENABLED and self.drop.count > 1 then
                -- Draw 1px gold border
                love.graphics.setColor(1, 0.8, 0, 1)
                love.graphics.rectangle("line", x, y, width, height)
            else
                -- Draw 1px white border
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.rectangle("line", x, y, width, height)
            end
        end
        
        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    return entity
end

return Drop
