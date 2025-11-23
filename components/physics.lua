-- Physics component
-- Physics properties for entities

local Physics = {}

function Physics.new(gravity, friction)
    return {
        id = "physics",
        gravity = gravity or 800,
        friction = friction or 0.95,
    }
end

return Physics
