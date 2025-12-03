local Registry = require "src.game.registries"
local BlockRef = require "data.blocks.ids"
local Biome = require "src.world.biome"

-- Get raw noise value at position (0.0-1.0 range, 0 = air)
function World.get_block_value(self, z, col, row)
    if row < 0 or row >= self.HEIGHT then
        return 0
    end

    -- Request column generation with high priority (visible column)
    self.generator:generate_column(z, col, true)

    local data = self.generator.data
    if data.columns[z] and
       data.columns[z][col] and
       data.columns[z][col][row] then
        return data.columns[z][col][row]
    end

    return 0
end

-- Get block at position (returns block ID)
-- Uses shared underground block distribution to prevent visible biome transition seams
function World.get_block_id(self, z, col, row)
    local value = self:get_block_value(z, col, row)
    -- Check if it's a direct block ID (< NOISE_OFFSET) or a noise value (>= NOISE_OFFSET)
    if value == BlockRef.SKY then
        return BlockRef.SKY
    elseif value == BlockRef.AIR then
        return BlockRef.AIR
    elseif value < self.NOISE_OFFSET then
        -- Direct block ID (grass, dirt, etc.)
        return value
    else
        -- Noise value: convert back to 0.0-1.0 range and use shared weighted lookup
        -- Shared underground distribution prevents visible seams at biome transitions
        local noise_value = (value - self.NOISE_OFFSET) / 100
        return Biome.get_underground_block(noise_value)
    end
end

-- Get block prototype at position
function World.get_block_def(self, z, col, row)
    local block_id = self.get_block_id(self, z, col, row)
    return Registry.Blocks:get(block_id)
end

-- Get biome at world position (x in world coordinates, z is layer)
-- Returns biome definition table with id, name, temperature, and humidity
-- Note: y coordinate is ignored - biomes are determined per-column, not per-block
-- This matches the terrain generator which uses zone_y = 0 for all blocks in a column
function World.get_biome(self, x, y, z)
    z = z or 0

    -- Convert world x coordinate to zone coordinate
    local zone_x = math.floor(x / self.BIOME_ZONE_SIZE)
    -- Use fixed zone_y = 0 to match terrain generator (biomes are column-based)
    local zone_y = 0

    -- Get temperature noise for this zone (uses biome_seed_offset for independent noise)
    -- Add z layer offset for slight variation between layers
    local temp_noise = love.math.noise(zone_x * 0.1 + z * 0.05, zone_y * 0.1, self.biome_seed_offset)

    -- Get humidity noise using a different seed offset (biome_seed_offset + 500)
    local humidity_noise = love.math.noise(zone_x * 0.1 + z * 0.05, zone_y * 0.1, self.biome_seed_offset + 500)

    -- Get biome definition from temperature and humidity
    return Biome.get_by_climate(temp_noise, humidity_noise)
end
