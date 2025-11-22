-- Collider component
-- Collision bounds for AABB collision detection

local Collider = {}

function Collider.new(width, height)
    return {
        id = "collider",
        width = width or 16,
        height = height or 16,
    }
end

return Collider
