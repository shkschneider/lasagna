local Love = require "core.love"
local Object = require "core.object"
local Registry = require "registries"
local BLOCKS = Registry.blocks()
local WorldData = require "src.data.worlddata"

-- Feature generators (disabled for now - will be re-enabled when worldgen is more advanced)
-- local generators = require "data.world"

-- Constants for terrain generation
local SURFACE_HEIGHT_RATIO = 0.75
local BASE_FREQUENCY = 0.02
local BASE_AMPLITUDE = 15
local DIRT_MIN_DEPTH = 5
local DIRT_MAX_DEPTH = 15

-- Seed offset for reproducible noise (set in Generator.load)
local seed_offset = 0

-- Octave noise using love.math.noise (fractal brownian motion)
-- love.math.noise returns values in [0, 1], we convert to [-1, 1] for terrain generation
local function octave_noise2d(x, y, octaves, persistence, lacunarity)
    octaves = octaves or 4
    persistence = persistence or 0.5
    lacunarity = lacunarity or 2.0

    local total = 0
    local frequency = 1
    local amplitude = 1
    local max_value = 0

    for i = 1, octaves do
        -- Use seed_offset as z coordinate for seeding
        local noise_val = love.math.noise(x * frequency, y * frequency, seed_offset + i)
        total = total + (noise_val * 2 - 1) * amplitude  -- Convert [0,1] to [-1,1]
        max_value = max_value + amplitude
        amplitude = amplitude * persistence
        frequency = frequency * lacunarity
    end

    return total / max_value
end

-- Simple 2D noise wrapper using love.math.noise
local function noise2d(x, y)
    -- Use seed_offset as z coordinate for seeding, convert [0,1] to [-1,1]
    return love.math.noise(x, y, seed_offset) * 2 - 1
end

-- Calculate surface height for a given column and layer
local function calculate_surface_height(col, z, world_height)
    local noise_val = octave_noise2d(col * BASE_FREQUENCY, z * 0.1, 4, 0.5, 2.0)
    local base_height = math.floor(world_height * SURFACE_HEIGHT_RATIO + noise_val * BASE_AMPLITUDE)
    if z == 1 then
        base_height = base_height + 5
    elseif z == -1 then
        base_height = base_height - 5
    end
    return base_height
end

-- Generate base terrain (air, stone, bedrock)
local function generate_air_stone_bedrock(column_data, world_col, base_height, world_height)
    for row = 0, world_height - 1 do
        if row >= base_height then
            column_data[row] = BLOCKS.STONE
        else
            column_data[row] = BLOCKS.AIR
        end
    end
    column_data[world_height - 2] = BLOCKS.BEDROCK
    column_data[world_height - 1] = BLOCKS.BEDROCK
end

-- Generate dirt and grass layers
local function generate_dirt_and_grass(column_data, world_col, z, base_height, world_height)
    local dirt_depth = DIRT_MIN_DEPTH + math.floor((DIRT_MAX_DEPTH - DIRT_MIN_DEPTH) *
        (noise2d(world_col * 0.05, z * 0.1) + 1) / 2)
    for row = base_height, math.min(base_height + dirt_depth - 1, world_height - 1) do
        if column_data[row] == BLOCKS.STONE then
            column_data[row] = BLOCKS.DIRT
        end
    end
    if base_height > 0 and base_height < world_height then
        if column_data[base_height] == BLOCKS.DIRT and
           column_data[base_height - 1] == BLOCKS.AIR then
            column_data[base_height] = BLOCKS.GRASS
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
    local base_height = calculate_surface_height(col, z, world_height)

    -- Base terrain generation
    generate_air_stone_bedrock(column_data, col, base_height, world_height)
    generate_dirt_and_grass(column_data, col, z, base_height, world_height)

    -- Features (disabled for now - will be re-enabled when worldgen is more advanced)
    -- generators(column_data, col, z, base_height, world_height)
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
