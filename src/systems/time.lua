local Love = require "core.love"
local Object = require "core.object"
local TimeScale = require "src.data.timescale"

-- Time system: manages time scaling and provides scaled delta time
local TimeSystem = Object {
    id = "time",
    priority = 2,  -- Run early, after state system
}

function TimeSystem.load(self)
    self.scale_obj = TimeScale.new(1)  -- 1 = normal time
    Love.load(self)
end

function TimeSystem.update(self, dt)
    -- This system doesn't need to update anything
    -- It just provides the scaled delta time
    Love.update(self, dt)
end

-- Get the current time scale
function TimeSystem.get_scale(self)
    return self.scale_obj.scale
end

-- Set the time scale
function TimeSystem.set_scale(self, scale)
    assert(type(scale) == "number" and scale >= 0)
    self.scale_obj.scale = scale
end

-- Get scaled delta time
function TimeSystem.get_scaled_dt(self, dt)
    return dt * self.scale_obj.scale
end

return TimeSystem
