-- Position component
-- World coordinates with layer information

local Position = {}

function Position.new(x, y, z)
    return {
        id = "position",
        x = x or 0,
        y = y or 0,
        z = z or 0,
        tostring = function(self)
            return string.format("%d,%d,%d", self.x, self.y, self.z)
        end
    }
end

return Position
