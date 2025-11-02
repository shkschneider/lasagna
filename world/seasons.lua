local Object = require("lib.object")
local log = require("lib.log")

-- Seasons system: manages the evolution of weather and day/night cycles
-- Each season has different characteristics affecting day length, sky colors, etc.
local Seasons = Object {
    -- Season definitions
    SPRING = "SPRING",
    SUMMER = "SUMMER",
    AUTUMN = "AUTUMN",
    WINTER = "WINTER",
    
    -- Season configurations
    SEASON_CONFIG = {
        SPRING = {
            name = "Spring",
            day_duration_mult = 1.0,      -- Normal day length
            night_duration_mult = 1.0,    -- Normal night length
            sky_color_mult = { 1.0, 1.05, 1.0, 1.0 }, -- Slight green tint
        },
        SUMMER = {
            name = "Summer",
            day_duration_mult = 1.3,      -- Longer days
            night_duration_mult = 0.7,    -- Shorter nights
            sky_color_mult = { 1.0, 1.0, 1.1, 1.0 }, -- Brighter, more blue
        },
        AUTUMN = {
            name = "Autumn",
            day_duration_mult = 1.0,      -- Normal day length
            night_duration_mult = 1.0,    -- Normal night length
            sky_color_mult = { 1.1, 0.95, 0.85, 1.0 }, -- Orange/warm tint
        },
        WINTER = {
            name = "Winter",
            day_duration_mult = 0.7,      -- Shorter days
            night_duration_mult = 1.3,    -- Longer nights
            sky_color_mult = { 0.95, 0.95, 1.0, 1.0 }, -- Slight blue/cold tint
        },
    },
}

function Seasons:new()
    -- Season cycle state
    self.season_order = { "SPRING", "SUMMER", "AUTUMN", "WINTER" }
    self.current_season_index = 1  -- Start with first season (Spring)
    self.current_season = self.season_order[self.current_season_index]
    self.season_time = 0           -- Time elapsed in current season (seconds)
    -- Convert SEASON_DURATION from in-game days to seconds
    -- One in-game day = DAY_DURATION + NIGHT_DURATION
    local day_cycle_duration = C.DAY_DURATION + C.NIGHT_DURATION
    self.season_duration = C.SEASON_DURATION * day_cycle_duration
end

-- Update season progression
function Seasons:update(dt)
    self.season_time = self.season_time + dt
    
    -- Check if season should change
    if self.season_time >= self.season_duration then
        self.season_time = self.season_time - self.season_duration
        self:advance_season()
    end
end

-- Advance to the next season
function Seasons:advance_season()
    self.current_season_index = (self.current_season_index % #self.season_order) + 1
    self.current_season = self.season_order[self.current_season_index]
    
    log.info(string.format("Season changed to: %s", self:get_season_name()))
end

-- Get current season configuration
function Seasons:get_config()
    return Seasons.SEASON_CONFIG[self.current_season]
end

-- Get day duration multiplier for current season
function Seasons:get_day_duration_mult()
    local config = self:get_config()
    return config and config.day_duration_mult or 1.0
end

-- Get night duration multiplier for current season
function Seasons:get_night_duration_mult()
    local config = self:get_config()
    return config and config.night_duration_mult or 1.0
end

-- Apply seasonal color multiplier to a sky color
function Seasons:apply_color_modifier(r, g, b, a)
    local config = self:get_config()
    if not config or not config.sky_color_mult then
        return r, g, b, a
    end
    
    local mult = config.sky_color_mult
    return (
        math.min(1.0, r * mult[1]),
        math.min(1.0, g * mult[2]),
        math.min(1.0, b * mult[3]),
        math.min(1.0, a * mult[4])
    )
end

-- Get the current season name
function Seasons:get_season_name()
    local config = self:get_config()
    return config and config.name or "Unknown"
end

-- Get season progress as a percentage (0.0 to 1.0)
function Seasons:get_season_progress()
    return self.season_time / self.season_duration
end

-- Get formatted season string with progress
function Seasons:get_season_string()
    local progress = math.floor(self:get_season_progress() * 100)
    return string.format("%s (%d%%)", self:get_season_name(), progress)
end

return Seasons
