local PhysicsComponent = {}

function PhysicsComponent.new(gravity, friction)
    return {
        __index = PhysicsComponent,
        id = "physics",
        priority = 10,  -- Physics updates early
        gravity = gravity or 800,
        friction = friction or 0.95,
    }
end

-- Component update method - applies gravity to parent entity's velocity
function PhysicsComponent.update(self, dt, entity)
    -- Apply gravity to velocity component if it exists
    -- Velocity uses x/y fields (not vx/vy)
    if entity and entity.velocity then
        entity.velocity.y = entity.velocity.y + self.gravity * dt
    end
end

return PhysicsComponent
