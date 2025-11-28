local Love = require "core.love"
local Object = require "core.object"
local WorldData = require "src.data.worlddata"
local BlockRef = require "data.blocks.ids"

--------------------------------------------------------------------------------
-- World Generation Overview
--------------------------------------------------------------------------------
-- World generation is done in multiple steps:
--
-- Step 1: 2D Noise Ground
--   - Uses 2D simplex noise to determine terrain density
--   - Creates the basic underground structure with varying block types
--
-- Step 2: Surface Cut
--   - Uses 1D multi-octave noise to create organic surface line
--   - Everything above the cut is air, below is terrain
--
-- Step 3: Surface Filling
--   - Adds grass on top and dirt below the surface cut
--   - Creates the recognizable surface layer
--
-- Step 4: Biomes (future expansion)
--   - Uses 2D simplex noise sampled in 64x64 zones
--   - 10 biome types based on noise rounded to 0.1 precision
--   - Will affect block types, vegetation, and terrain features
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Terrain Generation Parameters
--------------------------------------------------------------------------------

-- Value bucketing for debugging visualization
local BUCKET_SIZE = 0.1  -- Size of each value bucket (0.1 = 10 buckets from 0.0 to 1.0)

-- Surface smoothness: 0.0 = rough (all detail), 1.0 = smooth (only large hills)
-- Adjust this to control how rough/smooth the surface appears
local SURFACE_SMOOTHNESS = 0.75

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

--------------------------------------------------------------------------------
-- Noise functions using love.math.noise (Simplex noise)
-- love.math.noise returns values in [0, 1] range
--------------------------------------------------------------------------------

-- 1D simplex noise for surface cut line
local function simplex1d(x)
    return love.math.noise(x, seed_offset)
end

-- 2D simplex noise for terrain density map
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
local Z_SCALE_FACTOR = 0.1    -- Scale factor for z in noise calculations

-- Helper: round value to bucket precision
local function round_value(value)
    return math.floor(value / BUCKET_SIZE + 0.5) * BUCKET_SIZE
end

-- Multi-octave 1D noise for organic surface shape
-- Combines multiple frequencies for natural-looking terrain
-- SURFACE_SMOOTHNESS controls how much detail/roughness is visible
local function organic_surface_noise(col, z)
    -- Large rolling hills (always full strength)
    local hills = (simplex1d(col * HILL_FREQUENCY + z * Z_SCALE_FACTOR) - 0.5) * 2 * HILL_AMPLITUDE

    -- Medium terrain variation (reduced by smoothness)
    local medium_factor = 1.0 - (SURFACE_SMOOTHNESS * 0.5)  -- 50% reduction at max smoothness
    local variation = (simplex1d(col * TERRAIN_VAR_FREQUENCY + z * Z_SCALE_FACTOR + 100) - 0.5) * 2 * TERRAIN_VAR_AMPLITUDE * medium_factor

    -- Small surface detail (most affected by smoothness)
    local detail_factor = 1.0 - SURFACE_SMOOTHNESS  -- 100% reduction at max smoothness
    local detail = (simplex1d(col * DETAIL_FREQUENCY + z * Z_SCALE_FACTOR + 200) - 0.5) * 2 * DETAIL_AMPLITUDE * detail_factor

    return hills + variation + detail
end

--------------------------------------------------------------------------------
-- Pure World Generation Functions (no global G access)
-- Stores block IDs (0-99) or noise values as (NOISE_OFFSET + value*100)
-- Block ID 0 = AIR, 1 = DIRT, 2 = GRASS, etc.
--------------------------------------------------------------------------------

-- Generate terrain for a single column
-- Stores: 0 = air, block IDs for surface blocks, NOISE_OFFSET+ for noise-based terrain
-- Also adds surface layer with grass on top and dirt below (on top of generated ground)
local function generate_column_terrain(column_data, col, z, world_height)
    -- Calculate organic surface using multi-octave noise for Starbound-like terrain
    local surface_offset = organic_surface_noise(col, z)
    local cut_ratio = SURFACE_Y_RATIO + surface_offset
    local cut_row = math.floor(world_height * cut_ratio)

    -- Clamp cut row to valid range
    cut_row = math.max(1, math.min(world_height - 3, cut_row))

    -- Fill column with noise values (stored as NOISE_OFFSET + value*100)
    for row = 0, world_height - 1 do
        if row < cut_row then
            -- Above cut line = air (block ID 0)
            column_data[row] = BlockRef.AIR
        else
            -- Below cut line: use 2D simplex noise for terrain density
            local terrain_value = simplex2d(col * TERRAIN_FREQUENCY, row * TERRAIN_FREQUENCY + z * 10)
            -- Round to bucket precision for easier debugging
            terrain_value = round_value(terrain_value)
            -- Apply SOLID threshold: values below become air
            if terrain_value < SOLID then
                column_data[row] = BlockRef.AIR
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
        if column_data[row] and column_data[row] > 0 then
            surface_row = row
            break
        end
    end

    -- If we found a surface, add dirt and grass ON TOP (not replacing)
    if surface_row and surface_row > 0 then
        -- Random dirt depth based on column position (deterministic)
        local dirt_noise = simplex1d(col * 0.1 + z * 0.05 + 500)
        local dirt_depth = math.floor(DIRT_DEPTH_MIN + dirt_noise * (DIRT_DEPTH_MAX - DIRT_DEPTH_MIN + 1))
        dirt_depth = math.max(DIRT_DEPTH_MIN, math.min(DIRT_DEPTH_MAX, dirt_depth))

        -- Add dirt blocks on top of the surface (in the air above it)
        for i = 1, dirt_depth do
            local dirt_row = surface_row - i
            if dirt_row >= 0 then
                column_data[dirt_row] = BlockRef.DIRT
            end
        end

        -- Add grass on top of the dirt (only if we placed at least one dirt block)
        local grass_row = surface_row - dirt_depth - GRASS_DEPTH
        if grass_row >= 0 and dirt_depth > 0 then
            column_data[grass_row] = BlockRef.GRASS
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

    self.data = WorldData.new(G.debug and os.getenv("SEED") or math.round(os.time() + (love.timer.getTime() * 9 ^ 9)))
    assert(self.data.seed)
    Log.info(self.data.seed)
    Love.load(self)
    -- Set seed offset for love.math.noise (used as z coordinate for 2D noise seeding)
    -- Modulo keeps the offset in a reasonable range for noise function stability
    seed_offset = self.data.seed % 10000

    -- Initialize generation queues
    self.generation_queue_high = {}
    self.generation_queue_low = {}
    self.queued_columns = {}
    self.active_coroutines = {}

    local range = G.debug and BLOCK_SIZE or ((BLOCK_SIZE * BLOCK_SIZE) / 4)
    self:pregenerate_spawn_area(range)

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

-- Pre-generate columns around spawn area (32 to left and right)
-- Updates G.loader progress and yields if loader is active
function Generator.pregenerate_spawn_area(self, range)
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
