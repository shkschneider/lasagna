-- Controllable component
-- Handles movement and control logic for entities
-- Makes any entity with position, velocity, physics, collider, and stance controllable by user

local Controllable = {}

function Controllable.new(move_speed, jump_force)
    local instance = {
        id = "controllable",
        move_speed = move_speed or 150,
        jump_force = jump_force or 300,
    }
    
    -- Update the entity based on keyboard input
    -- Handles crouching, movement, and jumping
    -- Returns the desired velocity and stance changes
    function instance.update(self, dt, components, standing_height, crouching_height, world)
        local pos = components.position
        local vel = components.velocity
        local phys = components.physics
        local col = components.collider
        local stance = components.stance
        local vis = components.visual
        
        -- Handle crouching state
        local is_crouching = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
        local prev_stance = stance.current
        
        if is_crouching then
            stance.current = require("components.stance").CROUCHING
        else
            -- Check if entity can stand up (need clearance above)
            if prev_stance == require("components.stance").CROUCHING then
                local can_stand = true
                local standing_top = pos.y - standing_height / 2
                local top_row = math.floor(standing_top / world.BLOCK_SIZE)
                local left_col = math.floor((pos.x - col.width / 2) / world.BLOCK_SIZE)
                local right_col = math.floor((pos.x + col.width / 2 - EPSILON) / world.BLOCK_SIZE)
                
                -- Check if there's space to stand up
                for c = left_col, right_col do
                    local block_def = world:get_block_def(pos.z, c, top_row)
                    if block_def and block_def.solid then
                        can_stand = false
                        break
                    end
                end
                
                if can_stand then
                    stance.current = require("components.stance").STANDING
                else
                    -- Stay crouched, not enough space
                    stance.current = require("components.stance").CROUCHING
                end
            else
                stance.current = require("components.stance").STANDING
            end
        end
        
        -- Adjust position when changing stance to keep bottom at same level
        if prev_stance ~= stance.current then
            local prev_height = prev_stance == require("components.stance").STANDING and standing_height or crouching_height
            local new_height = stance.current == require("components.stance").STANDING and standing_height or crouching_height
            
            -- Keep the bottom at the same position
            local bottom_y = pos.y + prev_height / 2
            pos.y = bottom_y - new_height / 2
        end
        
        -- Update collider and visual heights
        if stance.current == require("components.stance").CROUCHING then
            col.height = crouching_height
            vis.height = crouching_height
        else
            col.height = standing_height
            vis.height = standing_height
        end
        
        -- Calculate movement speed based on stance
        local stance_modifier = 1.0
        if stance.current == require("components.stance").CROUCHING then
            stance_modifier = 0.5
        end
        local move_speed = self.move_speed * stance_modifier
        
        -- Horizontal movement
        vel.vx = 0
        if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            vel.vx = -move_speed
        end
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            vel.vx = move_speed
        end
        
        -- Jump
        if (love.keyboard.isDown("w") or love.keyboard.isDown("space") or love.keyboard.isDown("up")) and phys.on_ground then
            vel.vy = -self.jump_force
            phys.on_ground = false
        end
    end
    
    return instance
end

return Controllable
