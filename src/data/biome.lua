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

local BlockRef = require "data.blocks.ids"

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
-- Note: Lua arrays are 1-based, so IDs are 1-10 (not 0-9)
Biome.BIOMES = {
    -- Cold + Dry quadrant (IDs 1-3)
    { id = 1, name = "Tundra",      temperature = Biome.TEMPERATURE.FREEZING, humidity = Biome.HUMIDITY.ARID },
    { id = 2, name = "Taiga",       temperature = Biome.TEMPERATURE.COLD,     humidity = Biome.HUMIDITY.DRY },
    { id = 3, name = "Snowy Hills", temperature = Biome.TEMPERATURE.COLD,     humidity = Biome.HUMIDITY.NORMAL },
    -- Cold + Wet quadrant (IDs 4-5)
    { id = 4, name = "Forest",      temperature = Biome.TEMPERATURE.NORMAL,   humidity = Biome.HUMIDITY.WET },
    { id = 5, name = "Plains",      temperature = Biome.TEMPERATURE.NORMAL,   humidity = Biome.HUMIDITY.NORMAL },
    -- Hot + Wet quadrant (IDs 6-7)
    { id = 6, name = "Jungle",      temperature = Biome.TEMPERATURE.HOT,      humidity = Biome.HUMIDITY.HUMID },
    { id = 7, name = "Swamp",       temperature = Biome.TEMPERATURE.WARM,     humidity = Biome.HUMIDITY.WET },
    -- Hot + Dry quadrant (IDs 8-10)
    { id = 8, name = "Savanna",     temperature = Biome.TEMPERATURE.WARM,     humidity = Biome.HUMIDITY.DRY },
    { id = 9, name = "Badlands",    temperature = Biome.TEMPERATURE.HOT,      humidity = Biome.HUMIDITY.ARID },
    { id = 10, name = "Desert",    temperature = Biome.TEMPERATURE.HOT,      humidity = Biome.HUMIDITY.ARID },
}

-- Get biome ID from noise value (0.0-1.0)
-- Rounds to 0.1 precision, returns 1-10 (1-based for Lua arrays)
function Biome.noise_to_id(noise_value)
    -- Round to 0.1 precision and clamp to valid range (1-10)
    local id = math.floor(noise_value * 10 + 0.5) + 1
    return math.max(1, math.min(10, id))
end

-- Get biome ID from temperature and humidity noise values (0.0-1.0 each)
-- Uses a 2x2 matrix approach (returns 1-based IDs for Lua array):
--   temp < 0.5, humidity < 0.5 -> Cold + Dry (ids 1-3)
--   temp < 0.5, humidity >= 0.5 -> Cold + Wet (ids 4-5)
--   temp >= 0.5, humidity >= 0.5 -> Hot + Wet (ids 6-7)
--   temp >= 0.5, humidity < 0.5 -> Hot + Dry (ids 8-10)
function Biome.get_id_from_climate(temp_noise, humidity_noise)
    local is_hot = temp_noise >= 0.5
    local is_wet = humidity_noise >= 0.5

    if not is_hot and not is_wet then
        -- Cold + Dry: Tundra, Taiga, Snowy Hills (1-3)
        local sub_id = math.floor(temp_noise * 6)  -- 0-2
        return 1 + math.max(0, math.min(2, sub_id))
    elseif not is_hot and is_wet then
        -- Cold + Wet: Forest, Plains (4-5)
        local sub_id = math.floor((humidity_noise - 0.5) * 4)  -- 0-1
        return 4 + math.max(0, math.min(1, sub_id))
    elseif is_hot and is_wet then
        -- Hot + Wet: Jungle, Swamp (6-7)
        local sub_id = math.floor((temp_noise - 0.5) * 4)  -- 0-1
        return 6 + math.max(0, math.min(1, sub_id))
    else
        -- Hot + Dry: Savanna, Badlands, Desert (8-10)
        local sub_id = math.floor((temp_noise - 0.5) * 6)  -- 0-2
        return 8 + math.max(0, math.min(2, sub_id))
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

--------------------------------------------------------------------------------
-- Biome Surface Configuration
--------------------------------------------------------------------------------
-- Defines surface and subsurface blocks for each biome
-- This table is the single source of truth for biome-specific surface materials
Biome.SURFACES = {
    -- Cold + Dry biomes
    ["Tundra"]      = { surface = BlockRef.MUD,   subsurface = BlockRef.DIRT },
    ["Taiga"]       = { surface = BlockRef.MUD,   subsurface = BlockRef.DIRT },
    ["Snowy Hills"] = { surface = BlockRef.SNOW,  subsurface = BlockRef.STONE },
    
    -- Cold + Wet biomes (unchanged)
    ["Forest"]      = { surface = BlockRef.GRASS, subsurface = BlockRef.DIRT },
    ["Plains"]      = { surface = BlockRef.GRASS, subsurface = BlockRef.DIRT },
    
    -- Hot + Wet biomes
    ["Jungle"]      = { surface = BlockRef.GRASS, subsurface = BlockRef.MUD },
    ["Swamp"]       = { surface = BlockRef.GRASS, subsurface = BlockRef.MUD },
    
    -- Hot + Dry biomes
    ["Savanna"]     = { surface = BlockRef.SAND,  subsurface = BlockRef.SANDSTONE },
    ["Badlands"]    = { surface = BlockRef.SAND,  subsurface = BlockRef.SANDSTONE },
    ["Desert"]      = { surface = BlockRef.SAND,  subsurface = BlockRef.SANDSTONE },
}

-- Default surface configuration for unknown biomes
Biome.DEFAULT_SURFACE = { surface = BlockRef.GRASS, subsurface = BlockRef.DIRT }

-- Get surface block for a biome
function Biome.get_surface_block(biome)
    local config = Biome.SURFACES[biome.name] or Biome.DEFAULT_SURFACE
    return config.surface
end

-- Get subsurface block for a biome
function Biome.get_subsurface_block(biome)
    local config = Biome.SURFACES[biome.name] or Biome.DEFAULT_SURFACE
    return config.subsurface
end

--------------------------------------------------------------------------------
-- Biome Underground Block Configuration
--------------------------------------------------------------------------------
-- Defines weighted block spawn probabilities for underground terrain per biome
-- Weights are percentages (should sum to 100 for clarity, but auto-normalizes)
-- NOTE: Grass, Dirt, Sand, Sandstone, Snow are surface-only blocks
Biome.UNDERGROUND = {
    -- Cold + Dry biomes: more granite and slate (frozen/rocky)
    ["Tundra"] = {
        { block = BlockRef.STONE,     weight = 35 },
        { block = BlockRef.GRANITE,   weight = 25 },
        { block = BlockRef.SLATE,     weight = 20 },
        { block = BlockRef.LIMESTONE, weight = 10 },
        { block = BlockRef.GRAVEL,    weight = 5 },
        { block = BlockRef.CLAY,      weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
    ["Taiga"] = {
        { block = BlockRef.STONE,     weight = 35 },
        { block = BlockRef.GRANITE,   weight = 25 },
        { block = BlockRef.SLATE,     weight = 15 },
        { block = BlockRef.LIMESTONE, weight = 10 },
        { block = BlockRef.GRAVEL,    weight = 8 },
        { block = BlockRef.CLAY,      weight = 5 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
    ["Snowy Hills"] = {
        { block = BlockRef.STONE,     weight = 40 },
        { block = BlockRef.GRANITE,   weight = 25 },
        { block = BlockRef.SLATE,     weight = 15 },
        { block = BlockRef.LIMESTONE, weight = 10 },
        { block = BlockRef.GRAVEL,    weight = 5 },
        { block = BlockRef.BASALT,    weight = 5 },
    },
    
    -- Cold + Wet biomes: standard mix with more clay
    ["Forest"] = {
        { block = BlockRef.STONE,     weight = 40 },
        { block = BlockRef.GRANITE,   weight = 18 },
        { block = BlockRef.LIMESTONE, weight = 15 },
        { block = BlockRef.SLATE,     weight = 10 },
        { block = BlockRef.CLAY,      weight = 8 },
        { block = BlockRef.GRAVEL,    weight = 5 },
        { block = BlockRef.MUD,       weight = 2 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
    ["Plains"] = {
        { block = BlockRef.STONE,     weight = 40 },
        { block = BlockRef.GRANITE,   weight = 20 },
        { block = BlockRef.LIMESTONE, weight = 15 },
        { block = BlockRef.SLATE,     weight = 10 },
        { block = BlockRef.CLAY,      weight = 5 },
        { block = BlockRef.GRAVEL,    weight = 5 },
        { block = BlockRef.MUD,       weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
    
    -- Hot + Wet biomes: more mud and clay
    ["Jungle"] = {
        { block = BlockRef.STONE,     weight = 30 },
        { block = BlockRef.GRANITE,   weight = 15 },
        { block = BlockRef.LIMESTONE, weight = 15 },
        { block = BlockRef.MUD,       weight = 15 },
        { block = BlockRef.CLAY,      weight = 12 },
        { block = BlockRef.SLATE,     weight = 8 },
        { block = BlockRef.GRAVEL,    weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
    ["Swamp"] = {
        { block = BlockRef.STONE,     weight = 25 },
        { block = BlockRef.MUD,       weight = 25 },
        { block = BlockRef.CLAY,      weight = 20 },
        { block = BlockRef.LIMESTONE, weight = 12 },
        { block = BlockRef.GRANITE,   weight = 8 },
        { block = BlockRef.SLATE,     weight = 5 },
        { block = BlockRef.GRAVEL,    weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
    
    -- Hot + Dry biomes: more sandstone and limestone
    ["Savanna"] = {
        { block = BlockRef.STONE,     weight = 35 },
        { block = BlockRef.SANDSTONE, weight = 20 },
        { block = BlockRef.LIMESTONE, weight = 20 },
        { block = BlockRef.GRANITE,   weight = 10 },
        { block = BlockRef.SLATE,     weight = 8 },
        { block = BlockRef.GRAVEL,    weight = 5 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
    ["Badlands"] = {
        { block = BlockRef.STONE,     weight = 30 },
        { block = BlockRef.SANDSTONE, weight = 25 },
        { block = BlockRef.LIMESTONE, weight = 15 },
        { block = BlockRef.GRANITE,   weight = 12 },
        { block = BlockRef.CLAY,      weight = 8 },
        { block = BlockRef.SLATE,     weight = 5 },
        { block = BlockRef.GRAVEL,    weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
    ["Desert"] = {
        { block = BlockRef.SANDSTONE, weight = 35 },
        { block = BlockRef.STONE,     weight = 25 },
        { block = BlockRef.LIMESTONE, weight = 20 },
        { block = BlockRef.GRANITE,   weight = 10 },
        { block = BlockRef.SLATE,     weight = 5 },
        { block = BlockRef.GRAVEL,    weight = 3 },
        { block = BlockRef.BASALT,    weight = 2 },
    },
}

-- Default underground block weights for unknown biomes
Biome.DEFAULT_UNDERGROUND = {
    { block = BlockRef.STONE,     weight = 40 },
    { block = BlockRef.GRANITE,   weight = 20 },
    { block = BlockRef.LIMESTONE, weight = 15 },
    { block = BlockRef.SLATE,     weight = 10 },
    { block = BlockRef.GRAVEL,    weight = 5 },
    { block = BlockRef.CLAY,      weight = 5 },
    { block = BlockRef.MUD,       weight = 3 },
    { block = BlockRef.BASALT,    weight = 2 },
}

-- Pre-computed cumulative thresholds for each biome (populated on first access)
local underground_thresholds_cache = {}

-- Build cumulative thresholds from weights array
local function build_thresholds(weights)
    local thresholds = {}
    local total_weight = 0
    for _, entry in ipairs(weights) do
        total_weight = total_weight + entry.weight
    end
    local cumulative = 0
    for _, entry in ipairs(weights) do
        cumulative = cumulative + entry.weight
        table.insert(thresholds, {
            threshold = cumulative / total_weight,
            block = entry.block
        })
    end
    return thresholds
end

-- Get underground block thresholds for a biome (cached)
function Biome.get_underground_thresholds(biome_name)
    if not underground_thresholds_cache[biome_name] then
        local weights = Biome.UNDERGROUND[biome_name] or Biome.DEFAULT_UNDERGROUND
        underground_thresholds_cache[biome_name] = build_thresholds(weights)
    end
    return underground_thresholds_cache[biome_name]
end

-- Get underground block from noise value for a specific biome
function Biome.get_underground_block(biome_name, noise_value)
    local thresholds = Biome.get_underground_thresholds(biome_name)
    for _, entry in ipairs(thresholds) do
        if noise_value <= entry.threshold then
            return entry.block
        end
    end
    return BlockRef.STONE  -- fallback
end

return Biome
