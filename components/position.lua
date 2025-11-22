-- Position component
-- World coordinates with layer information

local Position = {}

function Position.new(x, y, layer)
    return {
        id = "position",
        x = x or 0,
        y = y or 0,
        layer = layer or 0,
        tostring = function()
            return string.format("%d,%d,%d", x, y, layer)
        end
    }
end

return Position
