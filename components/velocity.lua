-- Velocity component
-- Movement vector

local Velocity = {}

function Velocity.new(vx, vy)
    return {
        vx = vx or 0,
        vy = vy or 0,
    }
end

return Velocity
