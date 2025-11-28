local TimeScale = {
    id = "timescale",
    tostring = function(self)
        return string.format("%f", self.scale)
    end,
}

function TimeScale.new(scale)
    local timescale = {
        scale = scale or 1,
    }
    return setmetatable(timescale, { __index = TimeScale })
end

return TimeScale
