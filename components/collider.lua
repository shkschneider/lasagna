-- Collider Component
-- Defines collision bounds

local Collider = {}

function Collider.new(width, height)
    return {
        width = width or 0,
        height = height or 0,
    }
end

return Collider
