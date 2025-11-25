local noise = require "core.noise"
local generator = require "core.generator"
local Object = require "core.object"

-- GeneratorSystem handles asynchronous world column generation
-- using coroutines with priority queues for visible vs background columns

local GeneratorSystem = Object.new {
    id = "generator",
    priority = 5,  -- Run before WorldSystem (priority 10)
    -- Coroutine-based column generation
    generation_queue_high = {},  -- High priority queue (visible columns)
    generation_queue_low = {},   -- Low priority queue (background columns)
    queued_columns = {},         -- Hash table to track queued columns (O(1) lookup)
    active_coroutines = {},      -- Active generation coroutines
    max_coroutines = 8,          -- Maximum concurrent column generations
}

function GeneratorSystem.load(self, seed, _)
    -- Seed the noise library
    noise.seed(seed)

    -- Initialize generation queues
    self.generation_queue_high = {}
    self.generation_queue_low = {}
    self.queued_columns = {}
    self.active_coroutines = {}

    Object.load(self)
end

function GeneratorSystem.update(self, dt)
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
        local data = G.world.worlddata
        local already_done = (data.generated_columns[key] == true) or (data.generating_columns[key] == true)

        if not self.active_coroutines[key] and not already_done then
            -- Remove from tracking only when we actually start generating
            self.queued_columns[key] = nil

            local co = coroutine.create(function()
                self:generate_column_sync(col_info.z, col_info.col)
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
                data.generating_columns[key] = nil
            end
        else
            -- Column already generating or generated, remove from tracking
            self.queued_columns[key] = nil
        end
    end

    Object.update(self, dt)
end

-- Generate a single column immediately without yielding (for initial spawn area)
function GeneratorSystem.generate_column_immediate(self, z, col)
    local data = G.world.worlddata
    local key = string.format("%d_%d", z, col)

    -- Check if already generated
    if data.generated_columns[key] then
        return
    end

    -- Ensure column structure exists
    if not data.columns[z] then
        data.columns[z] = {}
    end
    if not data.columns[z][col] then
        data.columns[z][col] = {}
    end

    -- Generate terrain for this column
    generator(data.columns[z][col], col, z, data.height)

    -- Mark as generated immediately (no coroutine yield)
    data.generated_columns[key] = true
end

-- Pre-generate columns around spawn area (32 to left and right)
function GeneratorSystem.pregenerate_spawn_area(self)
    local spawn_col = BLOCK_SIZE  -- Same as used in find_spawn_position
    local range = BLOCK_SIZE  -- Generate initial columns to each side

    -- Generate for all layers
    for z = LAYER_MIN, LAYER_MAX do
        for offset = -range, range do
            local col = spawn_col + offset
            self:generate_column_immediate(z, col)
        end
    end
end

-- Generate a single column (function executed by coroutines)
function GeneratorSystem.generate_column_sync(self, z, col)
    local data = G.world.worlddata
    local key = string.format("%d_%d", z, col)

    -- Check if already generated
    if data.generated_columns[key] then
        return
    end

    -- Mark as generating to prevent duplicate generation
    data.generating_columns[key] = true

    -- Ensure column structure exists
    if not data.columns[z] then
        data.columns[z] = {}
    end
    if not data.columns[z][col] then
        data.columns[z][col] = {}
    end

    -- Generate terrain for this column
    generator(data.columns[z][col], col, z, data.height)

    -- Yield to prevent frame drops - allows other work to process before next column
    coroutine.yield()

    -- Column generation complete - mark as generated and no longer generating
    data.generating_columns[key] = nil
    data.generated_columns[key] = true
end

-- Queue a column for generation (non-blocking)
-- priority: true for high-priority queue (visible columns), false for low-priority queue (background)
function GeneratorSystem.generate_column(self, z, col, priority)
    local data = G.world.worlddata
    local key = string.format("%d_%d", z, col)

    -- Check if already generated
    if data.generated_columns[key] then
        return true  -- Already generated
    end

    -- Check if currently generating
    if data.generating_columns[key] then
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

return GeneratorSystem
