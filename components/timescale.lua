-- TimeScale component
-- Time manipulation

local TimeScale = {}

function TimeScale.new(scale, paused)
    return {
        id = "timescale",
        scale = scale or 1,
        paused = paused or false,
        tostring = function()
            return string.format("%.f", scale)
        end
    }
end

return TimeScale
