-- Collider component
-- Collision bounds for AABB collision detection

local Collider = {}

function Collider.new(width, height)
    return {
        width = width or 16,
        height = height or 16,
    }
end

return Collider
