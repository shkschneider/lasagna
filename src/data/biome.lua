--------------------------------------------------------------------------------
-- Biome Helper Functions
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
local BiomesRegistry = require "src.registries.biomes"

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

-- Get biome definition from ID (uses BiomesRegistry)
function Biome.get_by_id(biome_id)
    return BiomesRegistry:get(biome_id)
end

-- Get biome definition from noise value (legacy single-noise method)
function Biome.get_by_noise(noise_value)
    local id = Biome.noise_to_id(noise_value)
    return BiomesRegistry:get(id)
end

-- Get biome definition from temperature and humidity noise values
function Biome.get_by_climate(temp_noise, humidity_noise)
    local id = Biome.get_id_from_climate(temp_noise, humidity_noise)
    return BiomesRegistry:get(id)
end

--------------------------------------------------------------------------------
-- Biome Surface/Underground Helper Functions
--------------------------------------------------------------------------------

-- Default surface configuration for unknown biomes
local DEFAULT_SURFACE = BlockRef.GRASS
local DEFAULT_SUBSURFACE = BlockRef.DIRT

-- Shared underground block weights for all biomes
-- Using a single distribution prevents visible seams at biome transitions
-- Biome-specific blocks are used for surface/subsurface only
local SHARED_UNDERGROUND = {
    { block = BlockRef.STONE,     weight = 40 },
    { block = BlockRef.GRANITE,   weight = 20 },
    { block = BlockRef.LIMESTONE, weight = 15 },
    { block = BlockRef.SLATE,     weight = 10 },
    { block = BlockRef.GRAVEL,    weight = 5 },
    { block = BlockRef.CLAY,      weight = 5 },
    { block = BlockRef.MUD,       weight = 3 },
    { block = BlockRef.BASALT,    weight = 2 },
}

-- Get surface block for a biome
function Biome.get_surface_block(biome)
    if biome and biome.surface then
        return biome.surface
    end
    return DEFAULT_SURFACE
end

-- Get subsurface block for a biome
function Biome.get_subsurface_block(biome)
    if biome and biome.subsurface then
        return biome.subsurface
    end
    return DEFAULT_SUBSURFACE
end

-- Pre-computed cumulative thresholds for shared underground (cached once)
local shared_underground_thresholds = nil

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

-- Get shared underground block thresholds (cached, single distribution for all biomes)
function Biome.get_underground_thresholds()
    if not shared_underground_thresholds then
        shared_underground_thresholds = build_thresholds(SHARED_UNDERGROUND)
    end
    return shared_underground_thresholds
end

-- Get underground block from noise value (shared distribution for all biomes)
-- This prevents visible seams at biome transitions
function Biome.get_underground_block(noise_value)
    local thresholds = Biome.get_underground_thresholds()
    for _, entry in ipairs(thresholds) do
        if noise_value <= entry.threshold then
            return entry.block
        end
    end
    return BlockRef.STONE  -- fallback
end

return Biome
