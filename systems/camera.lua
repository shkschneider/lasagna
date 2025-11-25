local Object = require "core.object"
local VectorComponent = require "components.vector"

local CameraSystem = Object.new {
    id = "camera",
    priority = 90,
}

function CameraSystem.load(self)
    local x, y = G.player:get_position()
    self.position = VectorComponent.new(x, y, nil)
    self.target = VectorComponent.new(0, 0, nil)
    self.smoothness = 5
end

function CameraSystem.update(self, dt)
    -- Get player position from Player
    local target_x, target_y = G.player:get_position()
    self.target.x = target_x
    self.target.y = target_y

    -- Smooth interpolation
    local dx = self.target.x - self.position.x
    local dy = self.target.y - self.position.y

    self.position.x = self.position.x + dx * self.smoothness * dt
    self.position.y = self.position.y + dy * self.smoothness * dt
end

function CameraSystem.get_offset(self)
    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()
    return self.position.x - screen_width / 2, self.position.y - screen_height / 2
end

return CameraSystem
