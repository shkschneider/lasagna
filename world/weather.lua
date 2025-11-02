local Object = require("lib.object")
local log = require("lib.log")

local Weather = Object {
    DAY = { 0.53, 0.81, 0.92, 1.0 }, -- light blue sky
    NIGHT = { 0.05, 0.05, 0.15, 1.0 }, -- dark night sky
}

function Weather:new()
    -- Day/night cycle state
    -- Start at noon (12:00) - half-way through the day cycle
    self.time = C.DAY_DURATION / 2  -- Half-way through the day (12:00)
    self.state = Weather.DAY
    log.info("Weather system initialized (starting at noon)")
end

function Weather:update(dt)
    self.time = self.time + dt

    local cycle_duration = self.state == Weather.DAY and C.DAY_DURATION or C.NIGHT_DURATION

    if self.time >= cycle_duration then
        self.time = self.time - cycle_duration
        self.state = self.state == Weather.DAY and Weather.NIGHT or Weather.DAY
        log.info(string.format("Time changed to: %s", self.state == Weather.DAY and "DAY" or "NIGHT"))
    end
end

-- Get the current sky color with smooth transition
function Weather:get_sky_color()
    local cycle_duration = self.state == Weather.DAY and C.DAY_DURATION or C.NIGHT_DURATION
    
    -- Transition duration: 5 seconds or 10% of cycle, whichever is smaller
    -- This prevents overly long transitions in shorter cycles
    local transition_duration = math.min(5, cycle_duration * 0.1)

    local from_color = self.state == Weather.DAY and Weather.DAY or Weather.NIGHT
    local to_color = self.state == Weather.DAY and Weather.NIGHT or Weather.DAY

    -- Calculate transition progress (only at end of cycle)
    local t = 0
    if self.time > (cycle_duration - transition_duration) then
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

-- Get the in-game time as hours and minutes (24h format)
-- Day cycle: 06:00 to 18:00 (12 hours), Night cycle: 18:00 to 06:00 (12 hours)
function Weather:get_time_24h()
    local day_start_hour = 6   -- Day starts at 06:00
    local night_start_hour = 18  -- Night starts at 18:00
    
    local hours, minutes
    
    if self.state == Weather.DAY then
        -- During day: map time progress (0 to DAY_DURATION) to hours (6 to 18)
        local day_progress = self.time / C.DAY_DURATION  -- 0.0 to 1.0
        local day_hours = day_start_hour + (day_progress * 12)  -- 6 to 18
        hours = math.floor(day_hours)
        minutes = math.floor((day_hours - hours) * 60)
    else
        -- During night: map time progress (0 to NIGHT_DURATION) to hours (18 to 30, wrapping to 6)
        local night_progress = self.time / C.NIGHT_DURATION  -- 0.0 to 1.0
        local night_hours = night_start_hour + (night_progress * 12)  -- 18 to 30
        if night_hours >= 24 then
            night_hours = night_hours - 24  -- Wrap around midnight
        end
        hours = math.floor(night_hours)
        minutes = math.floor((night_hours - hours) * 60)
    end
    
    return hours, minutes
end

-- Get formatted time string (HH:MM)
function Weather:get_time_string()
    local hours, minutes = self:get_time_24h()
    return string.format("%02d:%02d", hours, minutes)
end

return Weather
