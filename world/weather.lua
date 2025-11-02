local Object = require("lib.object")
local log = require("lib.log")

local Weather = Object {
    DAY = { 0.53, 0.81, 0.92, 1.0 }, -- light blue sky
    NIGHT = { 0.05, 0.05, 0.15, 1.0 }, -- dark night sky
}

function Weather:new()
    -- Day/night cycle state
    self.time = 0  -- time accumulator in seconds
    self.state = Weather.DAY
end

function Weather:update(dt)
    self.time = self.time + dt

    local cycle_duration = self.state == Weather.DAY and C.DAY_DURATION or C.NIGHT_DURATION

    if self.time >= cycle_duration then
        self.time = self.time - cycle_duration
        self.state = Weather.NIGHT
        log.info(string.format("Time changed to: %s", self.state == Weather.DAY and "DAY" or "NIGHT"))
    end
end

-- Get the current sky color with smooth transition
function Weather:get_sky_color()
    local transition_duration = 5  -- seconds for smooth transition
    local cycle_duration = self.state == Weather.DAY and C.DAY_DURATION or C.NIGHT_DURATION

    local from_color = self.state == Weather.DAY and Weather.DAY or Weather.NIGHT
    local to_color = self.state == Weather.DAY and Weather.NIGHT or Weather.DAY

    -- Calculate transition progress
    local t = 0
    if self.time < transition_duration then
        -- Beginning of cycle - transitioning from previous phase
        t = self.time / transition_duration
        from_color, to_color = to_color, from_color
        t = 1 - t
    elseif self.time > (cycle_duration - transition_duration) then
        -- End of cycle - transitioning to next phase
        t = (self.time - (cycle_duration - transition_duration)) / transition_duration
    end

    -- Interpolate between colors
    local r = from_color[1] + (to_color[1] - from_color[1]) * t
    local g = from_color[2] + (to_color[2] - from_color[2]) * t
    local b = from_color[3] + (to_color[3] - from_color[3]) * t
    local a = from_color[4] + (to_color[4] - from_color[4]) * t

    return r, g, b, a
end

-- Draw the sky background
function Weather:draw()
    local r, g, b, a = self:get_sky_color()
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)
end

return Weather
