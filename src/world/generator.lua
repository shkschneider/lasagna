local Love = require "core.love"
local Object = require "core.object"
local WorldSeed = require "src.world.seed"
local BlockRef = require "data.blocks.ids"
local Biome = require "src.world.biome"
local rng = require "libs.random"

--------------------------------------------------------------------------------
-- World Generation Overview
--------------------------------------------------------------------------------
-- World generation is done in multiple steps:
--
-- Step 1: 3D Noise Ground
--   - Uses 3D simplex noise to determine terrain density across layers
--   - Creates coherent underground structure with layer-aware variations
--   - Layers share similar terrain shape but differ in smoothness and height
--
-- Step 2: Surface Cut
--   - Uses multi-octave 3D noise to create organic surface line
--   - Layer-dependent smoothness: layer 1 (rough), layer 2 (smooth)
--   - Layer height offset: layer 1 is elevated relative to layer 2
--   - Everything above the cut is air, below is terrain
--
-- Step 3: Biome-Based Surface Filling
--   - Determines biome from temperature + humidity noise
--   - Uses BIOME_SURFACES table for surface/subsurface blocks per biome
--   - See BIOME_SURFACES table below for complete configuration
--
-- Step 4: Cleanup Pass
--   - Removes floating surface blocks above cave openings
--   - Ensures surface blocks have solid ground support
--
-- Step 5: Bedrock Layer
--   - Places bedrock at the bottom of each column
--   - Creates an unbreakable world floor
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Terrain Generation Parameters
--------------------------------------------------------------------------------

-- Value bucketing for debugging visualization
local BUCKET_SIZE = 0.1  -- Size of each value bucket (0.1 = 10 buckets from 0.0 to 1.0)

-- Surface smoothness: 0.0 = rough (all detail), 1.0 = smooth (only large hills)
-- Now layer-dependent: layer 1 = rough, layer 2 = smooth
local SURFACE_SMOOTHNESS_BASE = 0.2  -- Base smoothness for layer 1 (rough)

-- Solid threshold: values >= this are considered solid (not air)
-- Lower = more terrain, Higher = more air/caves
local SOLID = 0.33

-- Surface cut parameters for Starbound-like organic terrain
local SURFACE_Y_RATIO = 0.25  -- Base surface at 1/4 from top

-- Surface layer parameters
local GRASS_DEPTH = 1
local DIRT_DEPTH_MIN = 2  -- Minimum dirt depth below grass
local DIRT_DEPTH_MAX = 5  -- Maximum dirt depth below grass

-- Block ID offset: noise values (0.0-1.0) are stored as 100+ to distinguish from block IDs
-- Block IDs 0-99 are reserved for actual blocks, 100+ are noise values * 100
local NOISE_OFFSET = 100

-- Seed offset for reproducible noise (set in Generator.load)
local seed_offset = 0

-- Biome seed offset (different from terrain seed for independent noise)
local biome_seed_offset = 0

--------------------------------------------------------------------------------
-- Noise functions using love.math.noise (Simplex noise)
-- love.math.noise returns values in [0, 1] range
-- Now using 3D noise for coherent layer-aware terrain generation
--------------------------------------------------------------------------------

-- 3D simplex noise for layer-aware terrain generation
local function simplex3d(x, y, z)
    return love.math.noise(x, y, z + seed_offset)
end

-- 2D simplex noise for terrain density map (kept for compatibility)
local function simplex2d(x, y)
    return love.math.noise(x, y, seed_offset)
end

--------------------------------------------------------------------------------
-- Terrain Generation Constants
--------------------------------------------------------------------------------

-- Multi-octave noise for organic terrain shape
-- Large scale: rolling hills (always present)
local HILL_FREQUENCY = 0.005      -- Very large features
local HILL_AMPLITUDE = 0.08       -- Large height variation

-- Medium scale: terrain variation (reduced by smoothness)
local TERRAIN_VAR_FREQUENCY = 0.02  -- Medium features
local TERRAIN_VAR_AMPLITUDE = 0.03  -- Moderate variation

-- Small scale: surface detail (most affected by smoothness)
local DETAIL_FREQUENCY = 0.08     -- Small details
local DETAIL_AMPLITUDE = 0.01     -- Subtle variation

-- 2D terrain noise parameters
local TERRAIN_FREQUENCY = 0.05

-- Layer differentiation
-- Z_SCALE_FACTOR controls how different adjacent layers are:
-- - Too small (e.g., 0.1): layers nearly identical, less interesting
-- - Too large (e.g., 1.0): layers very different, potentially jarring
-- - Sweet spot (0.3-0.5): coherent but distinct
local Z_SCALE_FACTOR = 0.4    -- Scale factor for z in 3D noise
local LAYER_HEIGHT_OFFSET = 0.02  -- Height offset per layer (layer 1 higher, layer 2 lower)
local SMOOTHNESS_SCALE_FACTOR = 0.6  -- How much smoothness changes per layer (0.2 to 0.8 = 0.6 delta)

-- Y-offsets for different noise octaves (to create independent noise patterns)
local HILLS_Y_OFFSET = 0
local VARIATION_Y_OFFSET = 100
local DETAIL_Y_OFFSET = 200

-- Helper: round value to bucket precision
local function round_value(value)
    return math.floor(value / BUCKET_SIZE + 0.5) * BUCKET_SIZE
end

-- Calculate layer-dependent smoothness
-- Layer 1 (back): rough (smoothness = 0.2)
-- Layer 2 (front): smooth (smoothness = 0.8)
-- Expects z to be in the range [LAYER_MIN, LAYER_MAX] (layer index)
local function get_layer_smoothness(z)
    -- Map z from [1, 2] to smoothness [0.2, 0.8]
    -- z = 1: smoothness = 0.2 (rough)
    -- z = 2: smoothness = 0.8 (smooth)
    -- Clamp z to valid layer range for safety (uses globals LAYER_MIN, LAYER_MAX from main.lua)
    z = math.max(LAYER_MIN, math.min(LAYER_MAX, z))
    -- Formula: 0.2 + (z - 1) * 0.6 = 0.2 for z=1, 0.8 for z=2
    return SURFACE_SMOOTHNESS_BASE + ((z - LAYER_MIN) * SMOOTHNESS_SCALE_FACTOR)
end

-- Multi-octave 3D noise for organic surface shape
-- Combines multiple frequencies for natural-looking terrain
-- Layer smoothness increases with z: 1 (rough) < 2 (smooth)
local function organic_surface_noise(col, z)
    local smoothness = get_layer_smoothness(z)
    
    -- Layer-specific height offset: layer 1 is higher than layer 2
    -- Formula makes z=1 negative (higher) and z=2 positive (lower)
    local layer_offset = (z - 1.5) * LAYER_HEIGHT_OFFSET * 2
    
    -- Large rolling hills (always full strength, using 3D noise for coherence)
    local hills = (simplex3d(col * HILL_FREQUENCY, HILLS_Y_OFFSET, z * Z_SCALE_FACTOR) - 0.5) * 2 * HILL_AMPLITUDE

    -- Medium terrain variation (reduced by smoothness)
    local medium_factor = 1.0 - (smoothness * 0.5)  -- 50% reduction at max smoothness
    local variation = (simplex3d(col * TERRAIN_VAR_FREQUENCY, VARIATION_Y_OFFSET, z * Z_SCALE_FACTOR) - 0.5) * 2 * TERRAIN_VAR_AMPLITUDE * medium_factor

    -- Small surface detail (most affected by smoothness)
    local detail_factor = 1.0 - smoothness  -- 100% reduction at max smoothness
    local detail = (simplex3d(col * DETAIL_FREQUENCY, DETAIL_Y_OFFSET, z * Z_SCALE_FACTOR) - 0.5) * 2 * DETAIL_AMPLITUDE * detail_factor

    return hills + variation + detail + layer_offset
end

-- Get biome for a column based on temperature and humidity noise
-- Returns biome definition with temperature and humidity properties
-- Uses zone_y = 0 to match terrain generation (biomes are determined per-column, not per-block)
local function get_column_biome(col, z)
    -- Convert column to zone coordinates (same as World.get_biome but with y=0)
    local zone_x = math.floor((col * BLOCK_SIZE) / Biome.ZONE_SIZE)
    -- Use fixed zone_y = 0 for consistent column-based biome generation
    -- This ensures the same biome is used for the entire column during generation
    local zone_y = 0

    -- Get temperature noise
    local temp_noise = love.math.noise(zone_x * 0.1 + z * 0.05, zone_y * 0.1, biome_seed_offset)

    -- Get humidity noise using a different seed offset
    local humidity_noise = love.math.noise(zone_x * 0.1 + z * 0.05, zone_y * 0.1, biome_seed_offset + 500)

    return Biome.get_by_climate(temp_noise, humidity_noise)
end

--------------------------------------------------------------------------------
-- Pure World Generation Functions (no global G access)
-- Stores block IDs (0-99) or noise values as (NOISE_OFFSET + value*100)
-- Block ID 0 = SKY (transparent), 1 = AIR (underground), 2 = DIRT, etc.
--------------------------------------------------------------------------------

-- Generate terrain for a single column
-- Stores: SKY = sky, AIR = underground air, block IDs for surface blocks, NOISE_OFFSET+ for noise-based terrain
-- Also adds surface layer with biome-appropriate blocks on top and subsurface below
local function generate_column_terrain(column_data, col, z, world_height)
    -- Get biome for this column
    local biome = get_column_biome(col, z)
    local surface_block = Biome.get_surface_block(biome)
    local subsurface_block = Biome.get_subsurface_block(biome)

    -- Calculate organic surface using multi-octave noise for Starbound-like terrain
    local surface_offset = organic_surface_noise(col, z)
    local cut_ratio = SURFACE_Y_RATIO + surface_offset
    local cut_row = math.floor(world_height * cut_ratio)

    -- Clamp cut row to valid range
    cut_row = math.max(1, math.min(world_height - 3, cut_row))

    -- Fill column with noise values (stored as NOISE_OFFSET + value*100)
    -- Initially use SKY for all air (will convert underground SKY to AIR later)
    for row = 0, world_height - 1 do
        if row < cut_row then
            -- Above cut line = sky (block ID 0)
            column_data[row] = BlockRef.SKY
        else
            -- Below cut line: use 3D simplex noise for terrain density (coherent across layers)
            local terrain_value = simplex3d(col * TERRAIN_FREQUENCY, row * TERRAIN_FREQUENCY, z * Z_SCALE_FACTOR)
            -- Round to bucket precision for easier debugging
            terrain_value = round_value(terrain_value)
            -- Apply SOLID threshold: values below become sky (will be converted to AIR if underground)
            if terrain_value < SOLID then
                column_data[row] = BlockRef.SKY
            else
                -- Store noise value as offset (100 + value*100, so 0.5 becomes 150)
                column_data[row] = NOISE_OFFSET + math.floor(terrain_value * 100)
            end
        end
    end

    -- Second pass: add surface layer ON TOP of the generated terrain
    -- Find the first solid block from top (the surface)
    local surface_row = nil
    for row = 0, world_height - 1 do
        if column_data[row] and column_data[row] > BlockRef.AIR then
            surface_row = row
            break
        end
    end

    -- If we found a surface, add subsurface and surface blocks ON TOP (not replacing)
    if surface_row and surface_row > 0 then
        -- Random subsurface depth based on column position (deterministic, using 3D noise)
        local dirt_noise = simplex3d(col * 0.1, 500, z * 0.05)
        local dirt_depth = math.floor(DIRT_DEPTH_MIN + dirt_noise * (DIRT_DEPTH_MAX - DIRT_DEPTH_MIN + 1))
        dirt_depth = math.max(DIRT_DEPTH_MIN, math.min(DIRT_DEPTH_MAX, dirt_depth))

        -- Add subsurface blocks on top of the terrain (in the air above it)
        for i = 1, dirt_depth do
            local dirt_row = surface_row - i
            if dirt_row >= 0 then
                column_data[dirt_row] = subsurface_block
            end
        end

        -- Add surface block on top (only if we placed at least one subsurface block)
        local grass_row = surface_row - dirt_depth - GRASS_DEPTH
        if grass_row >= 0 and dirt_depth > 0 then
            column_data[grass_row] = surface_block
        end
    end

    -- Third pass: clean up floating surface blocks
    -- Remove surface/subsurface blocks that have an air gap below (falls into cave openings)
    for row = 0, world_height - 2 do
        local block = column_data[row]
        -- Check if this is a surface or subsurface block
        if block == BlockRef.DIRT or block == BlockRef.GRASS or
           block == BlockRef.SNOW or block == BlockRef.SAND or
           block == BlockRef.MUD or block == BlockRef.SANDSTONE then
            -- Check if the block immediately below is sky (empty)
            local below = column_data[row + 1]
            if below == BlockRef.SKY then
                -- This block is floating over air - remove it
                column_data[row] = BlockRef.SKY
            end
        end
    end

    -- Fourth pass: place bedrock at the bottom of the column
    -- Creates an unbreakable world floor
    column_data[world_height - 1] = BlockRef.BEDROCK

    -- Fifth pass: convert SKY blocks without sky access to AIR
    -- SKY blocks below any solid block become AIR (underground/cave air)
    local found_solid = false
    for row = 0, world_height - 1 do
        local block = column_data[row]
        -- Check if we've encountered a solid block yet
        if block ~= BlockRef.SKY and block ~= BlockRef.AIR then
            found_solid = true
        end
        -- If we're below a solid block and this is SKY, convert to AIR
        if found_solid and block == BlockRef.SKY then
            column_data[row] = BlockRef.AIR
        end
    end
end

local Generator = Object {
    id = "generator",
    priority = 10,
    -- Coroutine-based column generation
    generation_queue_high = {},  -- High priority queue (visible columns)
    generation_queue_low = {},   -- Low priority queue (background columns)
    queued_columns = {},         -- Hash table to track queued columns (O(1) lookup)
    active_coroutines = {},      -- Active generation coroutines
    max_coroutines = 8,          -- Maximum concurrent column generations
}

-- Private helper: ensure column data structure exists
local function ensure_column_structure(data, z, col)
    if not data.columns[z] then
        data.columns[z] = {}
    end
    if not data.columns[z][col] then
        data.columns[z][col] = {}
    end
end

-- Private helper: run generators for a column
local function run_generator(self, z, col)
    local column_data = self.data.columns[z][col]
    local world_height = self.data.height

    -- Generate terrain using the new approach:
    -- 1. Surface from 1D noise at ~1/4 from top
    -- 2. Air above, stone below
    -- 3. Caves carved with 2D noise
    -- 4. Grass on surface, dirt below grass
    generate_column_terrain(column_data, col, z, world_height)
end

function Generator.load(self)
    local t = love.timer.getTime()

    -- Only create new WorldSeed if not already set (e.g., by loader with saved seed)
    if not self.data or not self.data.seed then
        self.data = WorldSeed.new(G.debug and os.getenv("SEED") or rng(rng()))
    end
    assert(self.data.seed)
    Log.info(self.data.seed)
    Love.load(self)
    -- Set seed offset for love.math.noise (used as z coordinate for 2D noise seeding)
    -- Modulo keeps the offset in a reasonable range for noise function stability
    seed_offset = self.data.seed % 10000

    -- Set biome seed offset (different from terrain seed for independent noise)
    biome_seed_offset = (self.data.seed % 10000) + 1000

    -- Initialize generation queues
    self.generation_queue_high = {}
    self.generation_queue_low = {}
    self.queued_columns = {}
    self.active_coroutines = {}

    self:pregenerate_spawn_area(nil)

    Log.verbose(string.format("Took %fs", love.timer.getTime() - t))
end

function Generator.update(self, dt)
    -- Process pending column generation coroutines
    local completed = {}

    for key, co in pairs(self.active_coroutines) do
        local status = coroutine.status(co)
        if status == "dead" then
            table.insert(completed, key)
        elseif status == "suspended" then
            -- Resume the coroutine for a bit
            local success, err = coroutine.resume(co)
            if not success then
                Log.error("World generation coroutine error:", err)
                table.insert(completed, key)
            end
        end
    end

    -- Clean up completed coroutines and queued tracking
    for _, key in ipairs(completed) do
        self.active_coroutines[key] = nil
        self.queued_columns[key] = nil
    end

    -- Count active coroutines
    local active_count = 0
    for _ in pairs(self.active_coroutines) do
        active_count = active_count + 1
    end

    -- Start new coroutines if we have capacity and pending columns
    -- Process high priority queue first, then low priority
    while active_count < self.max_coroutines do
        local col_info = nil

        -- Try high priority queue first
        if #self.generation_queue_high > 0 then
            col_info = table.remove(self.generation_queue_high, 1)
        elseif #self.generation_queue_low > 0 then
            col_info = table.remove(self.generation_queue_low, 1)
        else
            break  -- No more columns to generate
        end

        local key = string.format("%d_%d", col_info.z, col_info.col)

        -- Check if not already generating or generated
        local already_done = (self.data.generated_columns[key] == true) or (self.data.generating_columns[key] == true)

        if not self.active_coroutines[key] and not already_done then
            -- Remove from tracking only when we actually start generating
            self.queued_columns[key] = nil

            local co = coroutine.create(function()
                self:generate_column_async(col_info.z, col_info.col)
            end)
            self.active_coroutines[key] = co
            active_count = active_count + 1

            -- Start the coroutine
            local success, err = coroutine.resume(co)
            if not success then
                Log.error("World generation coroutine error:", err)
                self.active_coroutines[key] = nil
                active_count = active_count - 1
                -- Clear generating flag on error
                self.data.generating_columns[key] = nil
            end
        else
            -- Column already generating or generated, remove from tracking
            self.queued_columns[key] = nil
        end
    end

    Love.update(self, dt)
end

-- Generate a single column immediately without yielding (for initial spawn area)
function Generator.generate_column_immediate(self, z, col)
    local key = string.format("%d_%d", z, col)

    -- Check if already generated
    if self.data.generated_columns[key] then
        return
    end

    ensure_column_structure(self.data, z, col)
    run_generator(self, z, col)
    self.data.generated_columns[key] = true
end

-- Pre-generate columns around spawn area
-- Updates G.loader progress and yields if loader is active
function Generator.pregenerate_spawn_area(self, range)
    local width, _ = love.graphics.getDimensions()
    range = math.clamp(math.floor(width / BLOCK_SIZE / 2), range or 0, math.ceil(width / BLOCK_SIZE))
    Log.debug("PreGen", "+/-" .. tostring(range))

    local spawn_col = BLOCK_SIZE  -- Same as used in find_spawn_position

    -- Calculate total columns to generate (for progress tracking)
    local num_layers = LAYER_MAX - LAYER_MIN + 1
    local total_columns = num_layers * (range * 2 + 1)
    local current_column = 0

    -- Check if loader is active (we're in loading coroutine)
    local loader_active = G.loader and G.loader:is_active()

    -- Generate for all layers
    for z = LAYER_MIN, LAYER_MAX do
        for offset = -range, range do
            local col = spawn_col + offset
            self:generate_column_immediate(z, col)
            current_column = current_column + 1
            -- Update loader progress and yield every num_layers columns
            -- This yields once per unique x-position (after generating all 3 layers for that column)
            if loader_active and current_column % num_layers == 0 then
                -- Map column progress to 10%-90% range
                G.loader:set_progress(0.1 + (current_column / total_columns) * 0.8)
                coroutine.yield()
            end
        end
    end
end

-- Generate a single column (coroutine body - yields once during generation)
function Generator.generate_column_async(self, z, col)
    local key = string.format("%d_%d", z, col)

    -- Check if already generated
    if self.data.generated_columns[key] then
        return
    end

    -- Mark as generating to prevent duplicate generation
    self.data.generating_columns[key] = true

    ensure_column_structure(self.data, z, col)
    run_generator(self, z, col)

    -- Yield to prevent frame drops - allows other work to process before next column
    coroutine.yield()

    -- Column generation complete - mark as generated and no longer generating
    self.data.generating_columns[key] = nil
    self.data.generated_columns[key] = true
end

-- Queue a column for generation (non-blocking)
-- priority: true for high-priority queue (visible columns), false for low-priority queue (background)
function Generator.generate_column(self, z, col, priority)
    local key = string.format("%d_%d", z, col)

    -- Check if already generated
    if self.data.generated_columns[key] then
        return true  -- Already generated
    end

    -- Check if currently generating
    if self.data.generating_columns[key] then
        return false  -- Currently generating
    end

    -- Check if coroutine is active
    if self.active_coroutines[key] then
        return false  -- Currently generating
    end

    -- Check if already queued (O(1) lookup)
    if self.queued_columns[key] then
        return false  -- Already queued
    end

    -- Add to generation queue
    local col_info = {z = z, col = col}

    if priority then
        -- High priority: add to high priority queue (O(1))
        table.insert(self.generation_queue_high, col_info)
    else
        -- Normal priority: add to low priority queue (O(1))
        table.insert(self.generation_queue_low, col_info)
    end

    -- Track that this column is queued (O(1))
    self.queued_columns[key] = true

    return false  -- Queued for generation
end

return Generator
