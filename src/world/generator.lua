local Love = require "core.love"
local Object = require "core.object"
local Registry = require "registries"
local BLOCKS = Registry.blocks()
local WorldData = require "src.data.worlddata"

-- Seed offset for reproducible noise (set in Generator.load)
local seed_offset = 0

--------------------------------------------------------------------------------
-- Noise functions using love.math.noise
--------------------------------------------------------------------------------

-- 1D noise for surface cut line
-- Returns value in [0, 1] range
local function noise1d(x)
    return love.math.noise(x, seed_offset)
end

-- 2D noise for terrain density
-- Returns value in [0, 1] range
local function noise2d(x, y)
    return love.math.noise(x, y, seed_offset)
end

--------------------------------------------------------------------------------
-- Terrain Generation Constants
--------------------------------------------------------------------------------

-- Surface cut parameters
local SURFACE_Y_RATIO = 0.25  -- Base surface at 1/4 from top
local CUT_FREQUENCY = 0.02    -- 1D noise frequency for surface variation
local CUT_AMPLITUDE = 0.1     -- How much the cut line varies

-- 2D terrain noise parameters
local TERRAIN_FREQUENCY = 0.05
local TERRAIN_THRESHOLD = 0.5  -- Below this = air (caves), above = stone

--------------------------------------------------------------------------------
-- Pure World Generation Functions (no global G access)
--------------------------------------------------------------------------------

-- Generate terrain for a single column using:
-- 1. 2D noise to create terrain density map
-- 2. 1D noise to determine surface cut line
-- 3. Final pass: grass on surface, dirt below
local function generate_column_terrain(column_data, col, z, world_height)
    -- Calculate surface cut line using 1D noise
    local cut_noise = noise1d(col * CUT_FREQUENCY + z * 0.1)
    local cut_ratio = SURFACE_Y_RATIO + (cut_noise - 0.5) * CUT_AMPLITUDE * 2
    local cut_row = math.floor(world_height * cut_ratio)
    
    -- Layer offset
    if z == 1 then
        cut_row = cut_row - 3
    elseif z == -1 then
        cut_row = cut_row + 3
    end
    cut_row = math.max(1, math.min(world_height - 3, cut_row))
    
    -- Fill column using 2D noise for terrain density
    for row = 0, world_height - 1 do
        if row < cut_row then
            -- Above cut line = always air
            column_data[row] = BLOCKS.AIR
        else
            -- Below cut line: use 2D noise to determine if stone or air (cave)
            local terrain_noise = noise2d(col * TERRAIN_FREQUENCY, row * TERRAIN_FREQUENCY + z * 10)
            if terrain_noise > TERRAIN_THRESHOLD then
                column_data[row] = BLOCKS.STONE
            else
                column_data[row] = BLOCKS.AIR
            end
        end
    end
    
    -- Bedrock at bottom (always solid)
    column_data[world_height - 2] = BLOCKS.BEDROCK
    column_data[world_height - 1] = BLOCKS.BEDROCK
    
    -- Final pass: Add grass and dirt at surface
    -- Find first solid block from top and make it grass, dirt below
    for row = 0, world_height - 3 do
        if column_data[row] == BLOCKS.STONE then
            if row > 0 and column_data[row - 1] == BLOCKS.AIR then
                column_data[row] = BLOCKS.GRASS
                if row + 1 < world_height - 2 and column_data[row + 1] == BLOCKS.STONE then
                    column_data[row + 1] = BLOCKS.DIRT
                end
            end
            break
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
