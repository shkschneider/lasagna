-- Camera System
-- Manages camera positioning and smooth following

local log = require "lib.log"
local Systems = require "systems"
local Camera = require "components.camera"
local Position = require "components.position"

local CameraSystem = {
    id = "camera",
    priority = 90,
    components = {},
}

function CameraSystem.load(self, x, y)
    self.components.position = Position.new(x, y, nil)
    log.debug("Camera:", self.components.position:tostring())
    self.components.camera = Camera.new(x, y, x, y, 5)
end

function CameraSystem.x(self)
    return self.components.camera.x
end

function CameraSystem.y(self)
    return self.components.camera.y
end

function CameraSystem.update(self, dt)
    local cam = self.components.camera

    -- Get player position from PlayerSystem
    local target_x, target_y = Systems.get("player"):get_position()
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
    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()
    return cam.x - screen_width / 2,
        cam.y - screen_height / 2
end

return CameraSystem
