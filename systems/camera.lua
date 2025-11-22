-- Camera System
-- Manages camera positioning and smooth following

local Camera = require("components.camera")

local CameraSystem = {
    priority = 90,
    components = {},
}

function CameraSystem.load(self, x, y)
    self.components.camera = Camera.new(x, y, x, y, 5)
    self.screen_width = 1280
    self.screen_height = 720
end

function CameraSystem.update(self, dt, target_x, target_y)
    local cam = self.components.camera

    cam.target_x = target_x
    cam.target_y = target_y

    -- Smooth interpolation
    local dx = cam.target_x - cam.x
    local dy = cam.target_y - cam.y

    cam.x = cam.x + dx * cam.smoothness * dt
    cam.y = cam.y + dy * cam.smoothness * dt
end

function CameraSystem.get_offset(self)
    local cam = self.components.camera
    return cam.x - self.screen_width / 2, cam.y - self.screen_height / 2
end

function CameraSystem.resize(self, width, height)
    self.screen_width = width
    self.screen_height = height
end

return CameraSystem

