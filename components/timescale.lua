-- TimeScale component
-- Time manipulation

local TimeScale = {}

function TimeScale.new(scale)
    return {
        id = "timescale",
        scale = scale or 1,
        paused = false,
        tostring = function(self)
            return string.format("%s:%f", tostring(not self.paused), self.scale)
        end
    }
end

return TimeScale
