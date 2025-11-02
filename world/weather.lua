local Object = require("lib.object")
local log = require("lib.log")

local Weather = Object {
    -- Sky colors for different times of day
    -- Sunrise: blend of day blue with warm golden tone
    -- Sunset: blend of night dark with warm orange tone
    SUNRISE = { 0.76, 0.71, 0.66, 1.0 },  -- soft golden-blue (day + warm glow)
    DAY = { 0.53, 0.81, 0.92, 1.0 },      -- light blue sky
    SUNSET = { 0.52, 0.27, 0.17, 1.0 },   -- muted warm tone (night + orange glow)
    NIGHT = { 0.05, 0.05, 0.15, 1.0 },    -- dark night sky
    MIDNIGHT = { 0.01, 0.01, 0.05, 1.0 }, -- deep black for midnight
}

function Weather:new()
    -- Day/night cycle state
    -- Start at noon (12:00) - half-way through the day cycle
    self.time = C.DAY_DURATION / 2  -- Half-way through the day (12:00)
    self.state = Weather.DAY
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

-- Get the current sky color based on time of day with smooth transitions
function Weather:get_sky_color()
    local hours, minutes = self:get_time_24h()
    local time_decimal = hours + (minutes / 60.0)

    local color
    if time_decimal >= 5 and time_decimal < 7 then
        -- Sunrise: 05:00 to 07:00 (transition from night to sunrise to day)
        local t = (time_decimal - 5) / 2
        if t < 0.5 then
            -- First half: night to sunrise
            local t2 = t * 2
            color = self:interpolate_color(Weather.NIGHT, Weather.SUNRISE, t2)
        else
            -- Second half: sunrise to day
            local t2 = (t - 0.5) * 2
            color = self:interpolate_color(Weather.SUNRISE, Weather.DAY, t2)
        end
    elseif time_decimal >= 7 and time_decimal < 17 then
        -- Full day: 07:00 to 17:00
        color = Weather.DAY
    elseif time_decimal >= 17 and time_decimal < 19 then
        -- Sunset: 17:00 to 19:00 (transition from day to sunset to night)
        local t = (time_decimal - 17) / 2
        if t < 0.5 then
            -- First half: day to sunset
            local t2 = t * 2
            color = self:interpolate_color(Weather.DAY, Weather.SUNSET, t2)
        else
            -- Second half: sunset to night
            local t2 = (t - 0.5) * 2
            color = self:interpolate_color(Weather.SUNSET, Weather.NIGHT, t2)
        end
    elseif time_decimal >= 19 or time_decimal < 5 then
        -- Night time: 19:00 to 05:00
        -- Transition to deepest black at midnight (00:00)
        if time_decimal >= 22 or time_decimal < 2 then
            -- Around midnight (22:00 to 02:00) - transition to/from midnight black
            local midnight_time
            if time_decimal >= 22 then
                midnight_time = time_decimal - 22  -- 0 to 2
            else
                midnight_time = time_decimal + 2   -- 2 to 4
            end

            if midnight_time < 2 then
                -- Approaching midnight: night to midnight
                local t = midnight_time / 2
                color = self:interpolate_color(Weather.NIGHT, Weather.MIDNIGHT, t)
            else
                -- After midnight: midnight to night
                local t = (midnight_time - 2) / 2
                color = self:interpolate_color(Weather.MIDNIGHT, Weather.NIGHT, t)
            end
        else
            -- Regular night (02:00 to 05:00 or 19:00 to 22:00)
            color = Weather.NIGHT
        end
    else
        -- Default to night for any edge cases
        color = Weather.NIGHT
    end

    return color[1], color[2], color[3], color[4]
end

-- Helper function to interpolate between two colors
function Weather:interpolate_color(color1, color2, t)
    return {
        color1[1] + (color2[1] - color1[1]) * t,
        color1[2] + (color2[2] - color1[2]) * t,
        color1[3] + (color2[3] - color1[3]) * t,
        color1[4] + (color2[4] - color1[4]) * t,
    }
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
