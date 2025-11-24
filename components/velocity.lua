-- Velocity component
-- Movement vector

local Velocity = {}

function Velocity.new(vx, vy)
    local instance = {
        id = "velocity",
        priority = 20,  -- Velocity updates after physics
        vx = vx or 0,
        vy = vy or 0,
        enabled = true,  -- Allow toggling for debugging
    }
    
    -- Assign update and draw methods to instance
    instance.update = Velocity.update
    instance.draw = Velocity.draw
    
    return instance
end

-- Component update method - applies velocity to parent entity's position
function Velocity.update(self, dt, entity)
    if not self.enabled then return end
    
    -- Apply velocity to position component if it exists
    if entity and entity.position then
        entity.position.x = entity.position.x + self.vx * dt
        entity.position.y = entity.position.y + self.vy * dt
    end
end

-- Component draw method
function Velocity.draw(self)
    -- Velocity doesn't render anything
end

return Velocity
