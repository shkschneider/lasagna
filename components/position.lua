-- Position Component
-- Represents a 2D position with layer (z-coordinate)

local Position = {}

function Position.new(x, y, z)
    return {
        x = x or 0,
        y = y or 0,
        z = z or 0,
        tostring = function(self)
            return string.format("(%.1f, %.1f, %d)", self.x, self.y, self.z)
        end,
    }
end

return Position
