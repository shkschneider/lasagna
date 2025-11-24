-- Position Component
-- Represents a 2D position with layer (z-coordinate)

local Position = {}

function Position.new(x, y, z)
    return {
        x = x or 0,
        y = y or 0,
        z = z or 0,
    }
end

return Position
