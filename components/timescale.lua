-- TimeScale component
-- Time manipulation

local TimeScale = {}

function TimeScale.new(scale)
    return {
        id = "timescale",
        current = scale or 1,
    }
end

return TimeScale
