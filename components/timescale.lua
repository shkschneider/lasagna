-- TimeScale component
-- Time manipulation

local TimeScale = {}

function TimeScale.new(scale, paused)
    return {
        scale = scale or 1,
        paused = paused or false,
    }
end

return TimeScale
