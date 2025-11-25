local PhysicsComponent = {}

function PhysicsComponent.new(gravity, friction)
    local instance = {
        id = "physics",
        priority = 10,  -- Physics updates early
        enabled = true,  -- Can be disabled for complex collision handling (e.g., player)
        gravity = gravity or 800,
        friction = friction or 0.95,
    }

    -- Assign update method to instance
    instance.update = PhysicsComponent.update

    return instance
end

-- Component update method - applies gravity to parent entity's velocity
function PhysicsComponent.update(self, dt, entity)
    -- Skip if disabled (used for player with custom physics handling)
    if not self.enabled then
        return
    end
    -- Apply gravity to velocity component if it exists
    if entity and entity.velocity then
        entity.velocity.y = entity.velocity.y + self.gravity * dt
    end
end

return PhysicsComponent
