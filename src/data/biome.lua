--------------------------------------------------------------------------------
-- Biome Definitions
--------------------------------------------------------------------------------
-- Biomes are determined by two 2D simplex noise values (temperature & humidity)
-- Each axis uses 0.5 as the threshold, creating a 2x2 matrix of biome categories:
--
--                    DRY                    WET
--              +--------------+------------------------+
--   HOT/WARM   | Desert       | Jungle/Swamp           |
--              +--------------+------------------------+
--   COLD/COOL  | Tundra/Taiga | Forest/Plains          |
--              +--------------+------------------------+
--
-- Temperature noise: < 0.5 = cold, >= 0.5 = hot
-- Humidity noise: < 0.5 = dry, >= 0.5 = wet
--------------------------------------------------------------------------------

local Biome = {}

-- Biome zone size (in blocks)
Biome.ZONE_SIZE = 512

-- Biome temperature categories
Biome.TEMPERATURE = {
    FREEZING = "freezing",
    COLD = "cold",
    NORMAL = "normal",
    WARM = "warm",
    HOT = "hot",
}

-- Biome humidity categories
Biome.HUMIDITY = {
    ARID = "arid",
    DRY = "dry",
    NORMAL = "normal",
    WET = "wet",
    HUMID = "humid",
}

-- Biome definitions by ID
-- Organized by temperature (cold/hot) and humidity (dry/wet)
Biome.BIOMES = {
    -- Cold + Dry quadrant
    [0] = { id = 0, name = "Tundra",      temperature = Biome.TEMPERATURE.FREEZING, humidity = Biome.HUMIDITY.ARID },
    [1] = { id = 1, name = "Taiga",       temperature = Biome.TEMPERATURE.COLD,     humidity = Biome.HUMIDITY.DRY },
    [2] = { id = 2, name = "Snowy Hills", temperature = Biome.TEMPERATURE.COLD,     humidity = Biome.HUMIDITY.NORMAL },
    -- Cold + Wet quadrant
    [3] = { id = 3, name = "Forest",      temperature = Biome.TEMPERATURE.NORMAL,   humidity = Biome.HUMIDITY.WET },
    [4] = { id = 4, name = "Plains",      temperature = Biome.TEMPERATURE.NORMAL,   humidity = Biome.HUMIDITY.NORMAL },
    -- Hot + Wet quadrant
    [5] = { id = 5, name = "Jungle",      temperature = Biome.TEMPERATURE.HOT,      humidity = Biome.HUMIDITY.HUMID },
    [6] = { id = 6, name = "Swamp",       temperature = Biome.TEMPERATURE.WARM,     humidity = Biome.HUMIDITY.WET },
    -- Hot + Dry quadrant
    [7] = { id = 7, name = "Savanna",     temperature = Biome.TEMPERATURE.WARM,     humidity = Biome.HUMIDITY.DRY },
    [8] = { id = 8, name = "Badlands",    temperature = Biome.TEMPERATURE.HOT,      humidity = Biome.HUMIDITY.ARID },
    [9] = { id = 9, name = "Desert",      temperature = Biome.TEMPERATURE.HOT,      humidity = Biome.HUMIDITY.ARID },
}

-- Get biome ID from noise value (0.0-1.0)
-- Rounds to 0.1 precision, returns 0-9
function Biome.noise_to_id(noise_value)
    -- Round to 0.1 precision and clamp to valid range
    local id = math.floor(noise_value * 10 + 0.5)
    return math.max(0, math.min(9, id))
end

-- Get biome ID from temperature and humidity noise values (0.0-1.0 each)
-- Uses a 2x2 matrix approach:
--   temp < 0.5, humidity < 0.5 -> Cold + Dry (ids 0-2)
--   temp < 0.5, humidity >= 0.5 -> Cold + Wet (ids 3-4)
--   temp >= 0.5, humidity >= 0.5 -> Hot + Wet (ids 5-6)
--   temp >= 0.5, humidity < 0.5 -> Hot + Dry (ids 7-9)
function Biome.get_id_from_climate(temp_noise, humidity_noise)
    local is_hot = temp_noise >= 0.5
    local is_wet = humidity_noise >= 0.5
    
    if not is_hot and not is_wet then
        -- Cold + Dry: Tundra, Taiga, Snowy Hills (0-2)
        local sub_id = math.floor(temp_noise * 6)  -- 0-2
        return math.max(0, math.min(2, sub_id))
    elseif not is_hot and is_wet then
        -- Cold + Wet: Forest, Plains (3-4)
        local sub_id = math.floor((humidity_noise - 0.5) * 4)  -- 0-1
        return 3 + math.max(0, math.min(1, sub_id))
    elseif is_hot and is_wet then
        -- Hot + Wet: Jungle, Swamp (5-6)
        local sub_id = math.floor((temp_noise - 0.5) * 4)  -- 0-1
        return 5 + math.max(0, math.min(1, sub_id))
    else
        -- Hot + Dry: Savanna, Badlands, Desert (7-9)
        local sub_id = math.floor((temp_noise - 0.5) * 6)  -- 0-2
        return 7 + math.max(0, math.min(2, sub_id))
    end
end

-- Get biome definition from ID
function Biome.get_by_id(biome_id)
    return Biome.BIOMES[biome_id]
end

-- Get biome definition from noise value (legacy single-noise method)
function Biome.get_by_noise(noise_value)
    local id = Biome.noise_to_id(noise_value)
    return Biome.BIOMES[id]
end

-- Get biome definition from temperature and humidity noise values
function Biome.get_by_climate(temp_noise, humidity_noise)
    local id = Biome.get_id_from_climate(temp_noise, humidity_noise)
    return Biome.BIOMES[id]
end

return Biome
