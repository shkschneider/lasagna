-- Camera system with smooth follow

local camera = {}

function camera.new(x, y)
    return {
        x = x or 0,
        y = y or 0,
        target_x = x or 0,
        target_y = y or 0,
        smoothness = 5, -- Lower = smoother
    }
end

function camera.follow(self, target_x, target_y, dt)
    self.target_x = target_x
    self.target_y = target_y

    -- Smooth interpolation
    local dx = self.target_x - self.x
    local dy = self.target_y - self.y

    self.x = self.x + dx * self.smoothness * dt
    self.y = self.y + dy * self.smoothness * dt
end

function camera.get_offset(self, screen_width, screen_height)
    return self.x - screen_width / 2, self.y - screen_height / 2
end

return camera
