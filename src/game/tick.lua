-- Tick System
-- A tick is 1/10th of a second (0.1s)
-- Allows throttling expensive operations to run only every N ticks

local Tick = {}

-- Create a new tick throttler
-- @param n_ticks: Number of ticks to wait between function calls
-- @param func: Function to call when tick threshold is reached
-- @return Tick object
function Tick.new(n_ticks, func)
    assert(type(n_ticks) == "number" and n_ticks > 0, "n_ticks must be a positive number")
    assert(type(func) == "function", "func must be a function")
    
    local tick = {
        n_ticks = n_ticks,
        func = func,
        accumulated = 0,
        tick_duration = 0.1,  -- 1 tick = 1/10th second
    }
    
    return setmetatable(tick, { __index = Tick })
end

-- Update the tick throttler
-- @param dt: Delta time in seconds
-- Calls the function once when accumulated time exceeds the tick threshold
function Tick.update(self, dt)
    self.accumulated = self.accumulated + dt
    
    local threshold = self.n_ticks * self.tick_duration
    
    if self.accumulated >= threshold then
        self.func()
        -- Reset accumulator (keep overflow for precision)
        self.accumulated = self.accumulated - threshold
    end
end

-- Reset the tick accumulator
function Tick.reset(self)
    self.accumulated = 0
end

-- Get current tick progress (0 to 1)
function Tick.progress(self)
    local threshold = self.n_ticks * self.tick_duration
    return math.min(self.accumulated / threshold, 1)
end

return Tick
