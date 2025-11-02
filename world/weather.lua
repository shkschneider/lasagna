local Object = require("lib.object")
local log = require("lib.log")

local Weather = Object {
    DAY = { 0.53, 0.81, 0.92, 1.0 }, -- light blue sky
    NIGHT = { 0.05, 0.05, 0.15, 1.0 }, -- dark night sky
}

function Weather:new()
    -- Day/night cycle state
    -- Start at noon (12:00) - half a day has passed
    local total_cycle = C.DAY_DURATION + C.NIGHT_DURATION
    self.game_time = (total_cycle / 2)  -- Start at 12:00 (noon)
    self.time = C.DAY_DURATION / 2  -- Half-way through the day cycle
    self.state = Weather.DAY
    log.info("Weather system initialized (starting at noon)")
end

function Weather:update(dt)
    self.time = self.time + dt
    self.game_time = self.game_time + dt

    local cycle_duration = self.state == Weather.DAY and C.DAY_DURATION or C.NIGHT_DURATION

    if self.time >= cycle_duration then
        self.time = self.time - cycle_duration
        self.state = self.state == Weather.DAY and Weather.NIGHT or Weather.DAY
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

-- Get the in-game time as hours and minutes (24h format)
-- Full cycle (day+night) = 24 hours in-game
function Weather:get_time_24h()
    local total_cycle = C.DAY_DURATION + C.NIGHT_DURATION  -- seconds for full day
    local seconds_per_hour = total_cycle / 24  -- seconds per in-game hour
    
    -- Convert game time to hours (0-24)
    local total_hours = (self.game_time / seconds_per_hour) % 24
    local hours = math.floor(total_hours)
    local minutes = math.floor((total_hours - hours) * 60)
    
    return hours, minutes
end

-- Get formatted time string (HH:MM)
function Weather:get_time_string()
    local hours, minutes = self:get_time_24h()
    return string.format("%02d:%02d", hours, minutes)
end

return Weather
