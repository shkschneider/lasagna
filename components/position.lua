-- Position component
-- World coordinates with layer information

local Position = {}

function Position.new(x, y, layer)
    return {
        x = x or 0,
        y = y or 0,
        layer = layer or 0,
    }
end

return Position
