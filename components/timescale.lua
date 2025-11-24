-- TimeScale Component
-- Manages game time scaling and pause state

local TimeScale = {}

function TimeScale.new(scale)
    return {
        scale = scale or 1.0,
        paused = false,
    }
end

return TimeScale
