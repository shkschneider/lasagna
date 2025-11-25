-- TimeScale component
-- Time manipulation

local TimeComponent = {}

function TimeComponent.new(scale)
    return {
        id = "timescale",
        scale = scale or 1,
        paused = false,
        tostring = function(self)
            return string.format("%f:%s", self.scale, tostring(not self.paused))
        end
    }
end

return TimeComponent
