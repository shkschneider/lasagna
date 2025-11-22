-- Controllable component
-- Handles movement and control logic for entities

local Controllable = {}

function Controllable.new(move_speed, jump_force)
    return {
        id = "controllable",
        move_speed = move_speed or 150,
        jump_force = jump_force or 300,
    }
end

-- Process keyboard input and set velocity based on controls
-- Returns the desired velocity (vx, vy_impulse) based on input
function Controllable.process_input(self, current_vy, on_ground, stance_modifier)
    stance_modifier = stance_modifier or 1.0
    local move_speed = self.move_speed * stance_modifier
    
    local vx = 0
    local vy_impulse = nil
    
    -- Horizontal movement
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        vx = -move_speed
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        vx = move_speed
    end
    
    -- Jump
    if (love.keyboard.isDown("w") or love.keyboard.isDown("space") or love.keyboard.isDown("up")) and on_ground then
        vy_impulse = -self.jump_force
    end
    
    return vx, vy_impulse
end

return Controllable
