local Physics = {}

function Physics.new(gravity, friction)
    local instance = {
        id = "physics",
        priority = 10,  -- Physics updates early
        gravity = gravity or 800,
        friction = friction or 0.95,
    }

    -- Assign update and draw methods to instance
    instance.update = Physics.update
    instance.draw = Physics.draw

    return instance
end

-- Component update method - applies gravity to parent entity's velocity
function Physics.update(self, dt, entity)
    -- Apply gravity to velocity component if it exists
    if entity and entity.velocity then
        entity.velocity.vy = entity.velocity.vy + self.gravity * dt
    end
end

return Physics
