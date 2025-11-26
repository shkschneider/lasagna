-- Camera component
-- Camera state

local CameraComponent = {}

function CameraComponent.new(x, y, target_x, target_y, smoothness)
    local camera = {
        id = "camera",
        x = x or 0,
        y = y or 0,
        target_x = target_x or 0,
        target_y = target_y or 0,
        smoothness = smoothness or 5,
        tostring = function(self)
            return string.format("%d,%d", self.x, self.y)
        end
    }
    return setmetatable(camera, { __index = CameraComponent })
end

return CameraComponent
