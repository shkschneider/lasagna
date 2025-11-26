local VectorComponent = {}

function VectorComponent.new(x, y, z)
    local vector = {
        id = "vector",
        priority = 20,  -- after physics
        enabled = true,  -- Can be disabled for custom movement handling (e.g., player)
        x = x or 0,
        y = y or 0,
        z = z or LAYER_DEFAULT,
        tostring = function(self)
            return string.format("%d,%d,%d", self.x, self.y, self.z)
        end
    }
    return setmetatable(vector, { __index = VectorComponent })
end

-- Component update method - applies velocity to position
-- This component acts as the "velocity" when stored in entity.velocity
function VectorComponent.update(self, dt, entity)
    -- Skip if disabled (used for player with custom movement handling)
    if not self.enabled then
        return
    end
    -- Only apply velocity if this component IS the velocity component
    -- This prevents position component from incorrectly moving itself
    if entity and entity.velocity == self and entity.position then
        entity.position.x = entity.position.x + self.x * dt
        entity.position.y = entity.position.y + self.y * dt
    end
end

return VectorComponent
