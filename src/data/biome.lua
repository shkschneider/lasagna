--------------------------------------------------------------------------------
-- Biome Definitions
--------------------------------------------------------------------------------
-- Biomes are determined by 2D simplex noise sampled in 64x64 zones.
-- Noise values are rounded to 0.1 precision, giving 10 possible biome types:
--   0.0-0.1: FREEZING (1 type)
--   0.1-0.2: COLD (2 types)
--   0.2-0.3: COLD
--   0.3-0.4: NORMAL (4 types)
--   0.4-0.5: NORMAL
--   0.5-0.6: NORMAL
--   0.6-0.7: NORMAL
--   0.7-0.8: WARM (2 types)
--   0.8-0.9: WARM
--   0.9-1.0: HOT (1 type)
--------------------------------------------------------------------------------

local Biome = {}

-- Biome zone size (in blocks)
Biome.ZONE_SIZE = 64

-- Biome temperature categories
Biome.TEMPERATURE = {
    FREEZING = "freezing",
    COLD = "cold",
    NORMAL = "normal",
    WARM = "warm",
    HOT = "hot",
}

-- Biome definitions by ID (0-9, corresponding to noise value * 10)
Biome.BIOMES = {
    [0] = { id = 0, name = "Tundra",      temperature = Biome.TEMPERATURE.FREEZING },
    [1] = { id = 1, name = "Taiga",       temperature = Biome.TEMPERATURE.COLD },
    [2] = { id = 2, name = "Snowy Hills", temperature = Biome.TEMPERATURE.COLD },
    [3] = { id = 3, name = "Forest",      temperature = Biome.TEMPERATURE.NORMAL },
    [4] = { id = 4, name = "Plains",      temperature = Biome.TEMPERATURE.NORMAL },
    [5] = { id = 5, name = "Hills",       temperature = Biome.TEMPERATURE.NORMAL },
    [6] = { id = 6, name = "Swamp",       temperature = Biome.TEMPERATURE.NORMAL },
    [7] = { id = 7, name = "Savanna",     temperature = Biome.TEMPERATURE.WARM },
    [8] = { id = 8, name = "Badlands",    temperature = Biome.TEMPERATURE.WARM },
    [9] = { id = 9, name = "Desert",      temperature = Biome.TEMPERATURE.HOT },
}

-- Get biome ID from noise value (0.0-1.0)
-- Rounds to 0.1 precision, returns 0-9
function Biome.noise_to_id(noise_value)
    -- Round to 0.1 precision and clamp to valid range
    local id = math.floor(noise_value * 10 + 0.5)
    return math.max(0, math.min(9, id))
end

-- Get biome definition from ID
function Biome.get_by_id(biome_id)
    return Biome.BIOMES[biome_id]
end

-- Get biome definition from noise value
function Biome.get_by_noise(noise_value)
    local id = Biome.noise_to_id(noise_value)
    return Biome.BIOMES[id]
end

return Biome
