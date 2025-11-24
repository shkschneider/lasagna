-- TimeScale Component
-- Manages game time scaling and pause state

local TimeScale = {}

function TimeScale.new(scale)
    return {
        scale = scale or 1.0,
        paused = false,
        tostring = function(self)
            return string.format("%f:%s", self.scale, tostring(not self.paused))
        end
    }
end

return TimeScale
