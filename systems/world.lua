-- World System
-- Manages world generation, block storage, and world queries

local log = require "lib.log"
local noise = require "lib.noise"

local Systems = require "systems"
local Generator = require "systems.generator"
local WorldData = require "components.worlddata"
local Registry = require "registries"

local ONLY_CURRENT_LAYER_VISIBLE = false

local BLOCKS = Registry.blocks()

local WorldSystem = {
    id = "world",
    priority = 10,
    components = {},
    HEIGHT = 512,
    canvases = {},
    -- Coroutine-based column generation
    generation_queue_high = {},  -- High priority queue (visible columns)
    generation_queue_low = {},   -- Low priority queue (background columns)
    queued_columns = {},         -- Hash table to track queued columns (O(1) lookup)
    active_coroutines = {},      -- Active generation coroutines
    max_coroutines = 8,          -- Maximum concurrent column generations (increased for finer granularity)
}

function WorldSystem.load(self, seed, debug)
    -- Initialize components (no width - infinite horizontal)
    self.components.worlddata = WorldData.new(seed, self.HEIGHT)
    log.info("World:", self.components.worlddata.seed)

    -- Seed the noise library
    noise.seed(self.components.worlddata.seed)

    -- Create canvases for layer rendering
    self:create_canvases()
    
    -- Initialize generation queues
    self.generation_queue_high = {}
    self.generation_queue_low = {}
    self.queued_columns = {}
    self.active_coroutines = {}
end

function WorldSystem.create_canvases(self)
    local screen_width, screen_height = love.graphics.getDimensions()

    -- Create canvases for each layer
    self.canvases[-1] = love.graphics.newCanvas(screen_width, screen_height)
    self.canvases[0] = love.graphics.newCanvas(screen_width, screen_height)
    self.canvases[1] = love.graphics.newCanvas(screen_width, screen_height)
end

function WorldSystem.update(self, dt)
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
                log.error("World generation coroutine error:", err)
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
        local data = self.components.worlddata
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
                log.error("World generation coroutine error:", err)
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
end

function WorldSystem.draw(self)
    local player = Systems.get("player")
    local camera = Systems.get("camera")

    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()

    local camera_x, camera_y = camera:get_offset()
    local player_x, player_y, player_z = player:get_position()

    -- Clear screen with sky blue background
    love.graphics.clear(0.4, 0.6, 0.9, 1)

    -- Calculate visible area
    local start_col = math.floor(camera_x / BLOCK_SIZE) - 1
    local end_col = math.ceil((camera_x + screen_width) / BLOCK_SIZE) + 1
    local start_row = math.floor(camera_y / BLOCK_SIZE) - 1
    local end_row = math.ceil((camera_y + screen_height) / BLOCK_SIZE) + 1

    -- Clamp to world bounds (vertical only - horizontal is infinite)
    start_row = math.max(0, start_row)
    end_row = math.min(self.HEIGHT - 1, end_row)

    -- Calculate max layer to render (from LAYER_MIN up to player_z + 1, clamped to LAYER_MAX)
    local max_layer = math.min(player_z + 1, LAYER_MAX)
    local debug = Systems.get("debug")

    -- Draw each layer to its canvas
    for layer = LAYER_MIN, max_layer do
        local canvas = self.canvases[layer]
        if canvas then
            love.graphics.setCanvas(canvas)
            love.graphics.clear(0, 0, 0, 0)

            -- Check if this is the layer above the player
            local is_layer_above = (layer == player_z + 1)

            -- Set graphics state for outline drawing if this is the layer above
            if is_layer_above then
                love.graphics.setColor(1, 1, 1, 0.5)
                love.graphics.setLineWidth(1)
            end

            -- Draw blocks
            for col = start_col, end_col do
                for row = start_row, end_row do
                    local block_id = self:get_block_id(layer, col, row)
                    local proto = Registry.Blocks:get(block_id)

                    if proto and proto.solid then
                        local x = col * BLOCK_SIZE - camera_x
                        local y = row * BLOCK_SIZE - camera_y

                        if is_layer_above then
                            -- Draw only outlines for layer above player
                            -- Check each direction to see if there's air (draw edge if so)
                            
                            -- Check top
                            local top_block = self:get_block_id(layer, col, row - 1)
                            local top_proto = Registry.Blocks:get(top_block)
                            if not (top_proto and top_proto.solid) then
                                love.graphics.line(x, y, x + BLOCK_SIZE, y)
                            end
                            
                            -- Check bottom
                            local bottom_block = self:get_block_id(layer, col, row + 1)
                            local bottom_proto = Registry.Blocks:get(bottom_block)
                            if not (bottom_proto and bottom_proto.solid) then
                                love.graphics.line(x, y + BLOCK_SIZE, x + BLOCK_SIZE, y + BLOCK_SIZE)
                            end
                            
                            -- Check left
                            local left_block = self:get_block_id(layer, col - 1, row)
                            local left_proto = Registry.Blocks:get(left_block)
                            if not (left_proto and left_proto.solid) then
                                love.graphics.line(x, y, x, y + BLOCK_SIZE)
                            end
                            
                            -- Check right
                            local right_block = self:get_block_id(layer, col + 1, row)
                            local right_proto = Registry.Blocks:get(right_block)
                            if not (right_proto and right_proto.solid) then
                                love.graphics.line(x + BLOCK_SIZE, y, x + BLOCK_SIZE, y + BLOCK_SIZE)
                            end
                        else
                            -- Normal filled blocks for other layers
                            -- Ensure blocks are drawn with full opacity (alpha=1) to properly cover layers below
                            local r, g, b = proto.color[1] or 1, proto.color[2] or 1, proto.color[3] or 1
                            love.graphics.setColor(r, g, b, 1)
                            love.graphics.rectangle("fill", x, y, BLOCK_SIZE, BLOCK_SIZE)
                        end
                    end
                end
            end

            love.graphics.setCanvas()
        end
    end

    -- Composite layers to screen (only the layers we rendered: LAYER_MIN to player_z + 1)
    -- Set blend mode to ensure proper layering (solid blocks should completely cover layers below)
    love.graphics.setBlendMode("alpha", "premultiplied")

    -- Draw each layer from LAYER_MIN to max_layer
    for layer = LAYER_MIN, max_layer do
        -- Determine if this layer should be drawn based on visibility settings
        local should_draw = not ONLY_CURRENT_LAYER_VISIBLE
        if ONLY_CURRENT_LAYER_VISIBLE and debug then
            if debug.enabled then
                -- Debug mode on: only draw the player's current layer
                should_draw = (layer == player_z)
            else
                -- Debug mode off: draw all layers
                should_draw = true
            end
        end
        
        if should_draw then
            local canvas = self.canvases[layer]
            if canvas then
                if layer == player_z then
                    -- Full color: player is on this layer
                    love.graphics.setColor(1, 1, 1, 1)
                elseif layer == player_z + 1 then
                    -- Full color: this is the layer above player (outlines already have alpha)
                    love.graphics.setColor(1, 1, 1, 1)
                else
                    -- Dimmed: layers below player
                    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
                end
                love.graphics.draw(canvas, 0, 0)
            end
        end
    end

    -- Reset blend mode to default
    love.graphics.setBlendMode("alpha")
end

-- Helper: Convert column coordinate to chunk index and local column
function WorldSystem.col_to_chunk(self, col)
    -- Calculate chunk index using floor division
    local chunk_index = math.floor(col / CHUNK_SIZE)
    
    -- Calculate local column within the chunk
    -- We need local_col to always be in range [0, CHUNK_SIZE-1]
    local local_col = col - (chunk_index * CHUNK_SIZE)
    
    -- Verify the calculation is correct
    assert(local_col >= 0 and local_col < CHUNK_SIZE, 
           "Invalid local_col: " .. local_col .. " for col: " .. col)
    
    return chunk_index, local_col
end

-- Generate a single column (called within coroutine context)
function WorldSystem.generate_column_sync(self, z, col)
    local data = self.components.worlddata
    local key = string.format("%d_%d", z, col)

    -- Check if already generated
    if data.generated_columns[key] then
        return
    end
    
    -- Mark as generating to prevent duplicate generation
    data.generating_columns[key] = true

    -- Get chunk coordinates
    local chunk_index, local_col = self:col_to_chunk(col)
    
    -- Ensure chunk structure exists
    if not data.chunks[z] then
        data.chunks[z] = {}
    end
    if not data.chunks[z][chunk_index] then
        data.chunks[z][chunk_index] = {}
    end
    if not data.chunks[z][chunk_index][local_col] then
        data.chunks[z][chunk_index][local_col] = {}
    end
    
    -- Generate terrain for this column
    -- Pass: chunk_data, local_col, world_col, z, world_height
    Generator.generate_column(data.chunks[z][chunk_index], local_col, col, z, data.height)
    
    -- Single yield after generation to allow other coroutines to run
    coroutine.yield()
    
    -- Column generation complete - mark as generated and no longer generating
    data.generating_columns[key] = nil
    data.generated_columns[key] = true
end

-- Queue a column for generation (non-blocking)
-- priority: true for high-priority queue (visible columns), false for low-priority queue (background)
function WorldSystem.generate_column(self, z, col, priority)
    local data = self.components.worlddata
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

-- Get block at position
function WorldSystem.get_block_id(self, z, col, row)
    if row < 0 or row >= self.components.worlddata.height then
        return BLOCKS.AIR
    end

    local chunk_index, local_col = self:col_to_chunk(col)
    -- Request column generation with high priority (visible column)
    self:generate_column(z, col, true)

    local data = self.components.worlddata
    if data.chunks[z] and
       data.chunks[z][chunk_index] and
       data.chunks[z][chunk_index][local_col] and
       data.chunks[z][chunk_index][local_col][row] then
        return data.chunks[z][chunk_index][local_col][row]
    end

    return BLOCKS.AIR
end

-- Get block prototype at position
function WorldSystem.get_block_def(self, z, col, row)
    local block_id = self.get_block_id(self, z, col, row)
    return Registry.Blocks:get(block_id)
end

-- Set block at position
function WorldSystem.set_block(self, z, col, row, block_id)
    if row < 0 or row >= self.components.worlddata.height then
        return false
    end

    local chunk_index, local_col = self:col_to_chunk(col)
    -- Request column generation with high priority (user action)
    self:generate_column(z, col, true)

    local data = self.components.worlddata
    
    -- Ensure the chunk structure exists
    if not data.chunks[z] then
        data.chunks[z] = {}
    end
    if not data.chunks[z][chunk_index] then
        data.chunks[z][chunk_index] = {}
    end
    if not data.chunks[z][chunk_index][local_col] then
        data.chunks[z][chunk_index][local_col] = {}
    end

    data.chunks[z][chunk_index][local_col][row] = block_id
    return true
end

-- World to block coordinate conversion
function WorldSystem.world_to_block(self, world_x, world_y)
    return math.floor(world_x / BLOCK_SIZE), math.floor(world_y / BLOCK_SIZE)
end

-- Block to world coordinate conversion
function WorldSystem.block_to_world(self, col, row)
    return col * BLOCK_SIZE, row * BLOCK_SIZE
end

-- Find spawn position (simplified)
function WorldSystem.find_spawn_position(self, z)
    z = z or 0
    -- Find the surface by searching for the first solid block from top
    local col = BLOCK_SIZE
    for row = 0, self.components.worlddata.height - 1 do
        local block_def = self.get_block_def(self, z, col, row)
        if block_def and block_def.solid then
            -- Spawn in the last air block (just above the ground)
            -- This ensures the player spawns on the surface, not inside it
            local spawn_x = col * BLOCK_SIZE + BLOCK_SIZE / 2
            local spawn_y = (row - 9) * BLOCK_SIZE + BLOCK_SIZE / 2 -- FIXME magic 9
            return spawn_x, spawn_y, z
        end
    end

    -- Default spawn at top if no ground found
    return col * BLOCK_SIZE, 0, z
end

function WorldSystem.resize(self, width, height)
    self:create_canvases()
end

return WorldSystem
