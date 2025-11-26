-- TimeScale component
-- Time manipulation

local TimeComponent = {}

function TimeComponent.new(scale)
    return {
        id = "timescale",
        scale = scale or 1,
        tostring = function(self)
            return string.format("%f", self.scale)
        end
    }
end

return TimeComponent
