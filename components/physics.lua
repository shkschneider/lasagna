-- Physics Component
-- Contains physics properties like gravity and friction

local Physics = {}

function Physics.new(gravity, friction)
    return {
        gravity = gravity or 0,
        friction = friction or 1.0,
    }
end

return Physics
