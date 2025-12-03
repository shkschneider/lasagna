local Love = require "core.love"
local Object = require "core.object"

-- Fade system: manages screen fade-in/fade-out transitions
local FadeSystem = Object {
    id = "fade",
    priority = 5,  -- Run early, after state system
}

-- Fade effect constants
local FADE_DURATION = 1  -- 1 second fade duration

function FadeSystem.load(self)
    self.alpha = 0  -- 0 = transparent, 1 = black
    self.duration = FADE_DURATION
    self.timer = 0
    self.direction = nil  -- "in" (black to transparent) or "out" (transparent to black)
    Love.load(self)
end

function FadeSystem.update(self, dt)
    if self.direction then
        self.timer = self.timer + dt
        local progress = math.min(self.timer / self.duration, 1.0)

        if self.direction == "in" then
            -- Fade in: black (1.0) to transparent (0.0)
            self.alpha = 1.0 - progress
        elseif self.direction == "out" then
            -- Fade out: transparent (0.0) to black (1.0)
            self.alpha = progress
        end

        -- End fade when complete
        if progress >= 1.0 then
            self.direction = nil
            self.timer = 0
        end
    end
    
    Love.update(self, dt)
end

function FadeSystem.draw(self)
    -- Draw fade overlay
    if self.alpha > 0 then
        love.graphics.setColor(0, 0, 0, self.alpha)
        local width, height = love.graphics.getDimensions()
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end
    
    Love.draw(self)
end

-- Start fade-in effect (from black to transparent)
function FadeSystem.start_fade_in(self)
    self.direction = "in"
    self.timer = 0
    self.alpha = 1.0
end

-- Start fade-out effect (from transparent to black)
function FadeSystem.start_fade_out(self)
    self.direction = "out"
    self.timer = 0
    self.alpha = 0.0
end

-- Check if currently fading
function FadeSystem.is_fading(self)
    return self.direction ~= nil
end

return FadeSystem
