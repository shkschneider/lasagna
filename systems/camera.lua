-- Camera System
-- Manages camera positioning and smooth following

local log = require "lib.log"
local Object = require "core.object"
local Systems = require "core.systems"
local Camera = require "components.camera"
local Position = require "components.position"

local CameraSystem = Object.new {
    id = "camera",
    priority = 90,
}

function CameraSystem.load(self)
    local player = Systems.get("player")
    local x, y = player.position.x, player.position.y
    self.position = Position.new(x, y, nil)
    log.debug("Camera:", self.position:tostring())
    self.camera = Camera.new(x, y, x, y, 5)
end

function CameraSystem.x(self)
    return self.camera.x
end

function CameraSystem.y(self)
    return self.camera.y
end

function CameraSystem.update(self, dt)
    local cam = self.camera

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
    local cam = self.camera
    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()
    return cam.x - screen_width / 2,
        cam.y - screen_height / 2
end

return CameraSystem
