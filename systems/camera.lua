-- Camera System
-- Manages camera positioning and smooth following

local Object = require "core.object"
local Camera = require "components.camera"
local Position = require "components.position"

local CameraSystem = Object.new {
    id = "camera",
    priority = 90,
}

function CameraSystem.load(self)
    local x, y = G.player:get_position()
    self.position = Position.new(x, y, nil)
    self.camera = Camera.new(x, y, x, y, 5)
end

function CameraSystem.x(self)
    return self.camera.x
end

function CameraSystem.y(self)
    return self.camera.y
end

function CameraSystem.update(self, dt)
    -- Get player position from PlayerSystem
    local target_x, target_y = G.player:get_position()
    self.camera.target_x = target_x
    self.camera.target_y = target_y

    -- Smooth interpolation
    local dx = self.camera.target_x - self.camera.x
    local dy = self.camera.target_y - self.camera.y

    self.camera.x = self.camera.x + dx * self.camera.smoothness * dt
    self.camera.y = self.camera.y + dy * self.camera.smoothness * dt
end

function CameraSystem.get_offset(self)
    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()
    return self.camera.x - screen_width / 2,
        self.camera.y - screen_height / 2
end

return CameraSystem
