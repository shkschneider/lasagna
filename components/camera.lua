-- Camera component
-- Camera state

local Camera = {}

function Camera.new(x, y, target_x, target_y, smoothness)
    return {
        id = "camera",
        x = x or 0,
        y = y or 0,
        target_x = target_x or 0,
        target_y = target_y or 0,
        smoothness = smoothness or 5,
        tostring = function()
            return string.format("%d,%d", x, y)
        end
    }
end

return Camera
