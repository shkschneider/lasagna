local Love = require "core.love"
local Object = require "core.object"
local VectorComponent = require "components.vector"

local CameraSystem = Object {
    id = "camera",
    priority = 90,
}

function CameraSystem.load(self)
    local x, y = G.player:get_position()
    self.position = VectorComponent.new(x, y, nil)
    self.target = VectorComponent.new(0, 0, nil)
    self.smoothness = 5
    Love.load(self)
end

function CameraSystem.update(self, dt)
    -- Get player position from Player
    local target_x, target_y = G.player:get_position()
    self.target.x = target_x
    self.target.y = target_y

    -- Exponential interpolation that always follows the player, even at high speeds
    local dx = self.target.x - self.position.x
    local dy = self.target.y - self.position.y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- alpha = 1 - exp(-(base + gain * dist) * dt)
    -- This ensures camera catches up faster when player is far away
    local base = 5    -- Base follow speed
    local gain = 0.1  -- Extra speed per pixel of distance
    local alpha = 1 - math.exp(-(base + gain * dist) * dt)

    self.position.x = self.position.x + dx * alpha
    self.position.y = self.position.y + dy * alpha

    Love.update(self, dt)
end

function CameraSystem.get_offset(self)
    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()
    return self.position.x - screen_width / 2, self.position.y - screen_height / 2
end

return CameraSystem
