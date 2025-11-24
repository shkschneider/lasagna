-- Camera Component
-- Manages camera position and smoothing

local Camera = {}

function Camera.new(x, y, target_x, target_y, smoothness)
    return {
        x = x or 0,
        y = y or 0,
        target_x = target_x or 0,
        target_y = target_y or 0,
        smoothness = smoothness or 5,
    }
end

return Camera
