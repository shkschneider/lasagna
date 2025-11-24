-- TimeScale component
-- Time manipulation

local Time = {}

function Time.new(scale)
    return {
        id = "timescale",
        scale = scale or 1,
        paused = false,
        tostring = function(self)
            return string.format("%f:%s", self.scale, tostring(not self.paused))
        end
    }
end

return Time
