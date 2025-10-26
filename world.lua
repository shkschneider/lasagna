-- Simple World module (pure logic + optional drawing helper)
-- Responsibilities:
--  - generate per-layer surface heights and dirt/stone limits
--  - provide small query API (get_surface, get_block_type, width/height)
--  - support placing/removing/replacing blocks via a single set_block API
--  - provide a drawing helper: World:draw(z, canvas, blocks, block_size)
--
-- This version adds logging (lib.log) for:
--  - world creation (seed)
--  - adding / destroying / replacing blocks via World:set_block
--  - World:place_block still exists for compatibility but delegates to set_block where appropriate.
--
local noise = require("noise1d")
local Blocks = require("blocks") -- used for drawing placed blocks
local log = require("lib.log")   -- rxi/log.lua-style logging

local World = {}
World.__index = World

-- default options (keys are UPPERCASE)
local DEFAULTS = {
    WIDTH = 500,
    HEIGHT = 100,
    DIRT_THICKNESS = 10,
    STONE_THICKNESS = 10,
    LAYER_BASE_HEIGHTS = { [-1] = 20, [0] = 30, [1] = 40 },
    AMPLITUDE = { [-1] = 15, [0] = 10, [1] = 10 },
    FREQUENCY = { [-1] = 1/40, [0] = 1/50, [1] = 1/60 },
}

-- compatibility for unpack across Lua versions (Lua 5.2+ vs 5.1 / LuaJIT)
local unpack = table.unpack or unpack or function(t)
    return t[1], t[2], t[3], t[4]
end

-- create a new world instance
-- seed: number or string (passed to noise.init)
-- opts: table overrides from DEFAULTS (optional)
function World.new(seed, opts)
    opts = opts or {}
    local self = setmetatable({}, World)
    self.seed = seed
    -- shallow copy defaults, overridden by opts
    self.width = opts.width or DEFAULTS.WIDTH
    self.height = opts.height or DEFAULTS.HEIGHT
    self.dirt_thickness = opts.dirt_thickness or DEFAULTS.DIRT_THICKNESS
    self.stone_thickness = opts.stone_thickness or DEFAULTS.STONE_THICKNESS
    self.layer_base_heights = opts.layer_base_heights or DEFAULTS.LAYER_BASE_HEIGHTS
    self.amplitude = opts.amplitude or DEFAULTS.AMPLITUDE
    self.frequency = opts.frequency or DEFAULTS.FREQUENCY

    -- internal storage
    self.layers = {} -- layers[z] = { heights = {}, dirt_limit = {}, stone_limit = {} }
    self.placed = {} -- placed[z] = { [x] = { [y] = blockName_or_sentinel } }

    -- initialize noise and generate
    if self.seed ~= nil then
        math.randomseed(self.seed)
    end
    noise.init(self.seed)
    self:regenerate()

    -- log world creation
    log.info("World created with seed:", tostring(self.seed))
    return self
end

-- regenerate the world's layers (keeps the same seed unless you set self.seed)
function World:regenerate()
    if self.seed ~= nil then
        math.randomseed(self.seed)
    end
    noise.init(self.seed)

    for z = -1, 1 do
        local layer = { heights = {}, dirt_limit = {}, stone_limit = {} }
        local base = (self.layer_base_heights and self.layer_base_heights[z]) or DEFAULTS.LAYER_BASE_HEIGHTS[z]
        local amp = (self.amplitude and self.amplitude[z]) or DEFAULTS.AMPLITUDE[z]
        local freq = (self.frequency and self.frequency[z]) or DEFAULTS.FREQUENCY[z]

        for x = 1, self.width do
            local n = noise.perlin1d(x * freq + (z * 100))
            local top = math.floor(base + amp * n)
            -- clamp top inside world bounds (leave at least 1 row above and 1 below)
            top = math.max(1, math.min(self.height - 1, top))

            local dirt_lim = math.min(self.height, top + self.dirt_thickness)
            local stone_lim = math.min(self.height, top + self.dirt_thickness + self.stone_thickness)

            layer.heights[x] = top
            layer.dirt_limit[x] = dirt_lim
            layer.stone_limit[x] = stone_lim
        end

        self.layers[z] = layer
        -- reset placed overlay for this layer
        self.placed[z] = {}
    end
end

-- return surface/top (row number) for layer z at column x, or nil if out of range
-- NOTE: This computes the surface dynamically by scanning from top to bottom
-- and returning the first non-air block (considers placed overlay + procedural).
function World:get_surface(z, x)
    if x < 1 or x > self.width then return nil end
    -- iterate rows from top (1) downward and return first non-air block
    for y = 1, self.height do
        local t = self:get_block_type(z, x, y)
        if t and t ~= "air" and t ~= "out" then
            return y
        end
    end
    return nil
end

-- Place a block into the placed-overlay at (z, x, y)
-- blockName is a string like "grass", "dirt", "stone" that corresponds to Blocks[blockName]
-- Returns true on success, false and optional reason on failure.
-- Kept for compatibility; it will refuse to overwrite non-air procedural tiles.
function World:place_block(z, x, y, blockName)
    if not z or not x or not y or not blockName then
        return false, "invalid parameters"
    end
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return false, "out of bounds"
    end
    if not self.placed[z] then self.placed[z] = {} end
    if not self.placed[z][x] then self.placed[z][x] = {} end
    -- don't overwrite an existing placed block
    if self.placed[z][x][y] ~= nil and self.placed[z][x][y] ~= "__empty" then
        return false, "cell not empty (placed)"
    end
    -- also don't overwrite a world tile (grass/dirt/stone)
    local existing = self:get_block_type(z, x, y)
    if existing ~= "air" then
        return false, "cell not empty (world)"
    end

    self.placed[z][x][y] = blockName
    log.info(string.format("World: added block '%s' at z=%d x=%d y=%d", tostring(blockName), z, x, y))
    return true
end

-- set_block: unified setter that adds/removes/replaces placed overlay entries.
-- blockName:
--   - string (e.g. "grass"): set/overwrite placed block at this cell
--   - "__empty": mark procedural tile as removed (treat as air)
--   - nil: remove any placed overlay at that cell (if procedural exists it remains)
-- Returns (ok, reason/action)
function World:set_block(z, x, y, blockName)
    if not z or not x or not y then
        return false, "invalid parameters"
    end
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return false, "out of bounds"
    end

    if not self.placed[z] then self.placed[z] = {} end
    if not self.placed[z][x] then self.placed[z][x] = {} end

    local prev_placed = self.placed[z][x][y] -- may be nil, "__empty", or blockName
    local prev_type = self:get_block_type(z, x, y) -- resolves placed overlay or procedural

    -- Determine requested action
    if blockName == nil then
        -- remove any placed overlay; if there was a "__empty" sentinel, removing it will restore procedural
        if prev_placed ~= nil then
            self.placed[z][x][y] = nil
            log.info(string.format("World: removed placed overlay at z=%d x=%d y=%d (prev placed=%s, prev_type=%s)", z, x, y, tostring(prev_placed), tostring(prev_type)))
            return true, "removed placed overlay"
        end
        -- nothing to remove
        return false, "nothing to remove"
    end

    -- blockName == "__empty" means mark procedural tile removed
    if blockName == "__empty" then
        -- if there is an existing placed block, remove it instead (prefer player-placed removal)
        if prev_placed ~= nil and prev_placed ~= "__empty" then
            self.placed[z][x][y] = nil
            log.info(string.format("World: removed player-placed block at z=%d x=%d y=%d (was %s)", z, x, y, tostring(prev_placed)))
            return true, "removed placed"
        end
        -- otherwise write sentinel to mark as removed
        self.placed[z][x][y] = "__empty"
        log.info(string.format("World: removed procedural block (marked __empty) at z=%d x=%d y=%d (prev_type=%s)", z, x, y, tostring(prev_type)))
        return true, "removed procedural"
    end

    -- Otherwise blockName is a real block to set; this overwrites any existing placed overlay
    local action = nil
    if prev_type == "air" then
        action = "added"
    else
        -- if prev was placed and different, it's a replace of placed; if prev was procedural it's a replace
        action = "replaced"
    end

    self.placed[z][x][y] = blockName
    log.info(string.format("World: %s block '%s' at z=%d x=%d y=%d (prev_type=%s, prev_placed=%s)", action, tostring(blockName), z, x, y, tostring(prev_type), tostring(prev_placed)))
    return true, action
end

-- get block type at (z, x, by)
-- by = block-row (1..height), x = column
-- returns: "out" (out of world bounds), "air", "grass", "dirt", "stone" or any placed block name
function World:get_block_type(z, x, by)
    if x < 1 or x > self.width or by < 1 or by > self.height then
        return "out"
    end
    -- check placed overlay first
    if self.placed and self.placed[z] and self.placed[z][x] and self.placed[z][x][by] ~= nil then
        local pv = self.placed[z][x][by]
        -- special sentinel "__empty" used to mark that a procedural/generated block
        -- at this position was removed by the player; treat it as air.
        if pv == "__empty" then
            return "air"
        end
        return pv
    end

    local layer = self.layers[z]
    if not layer then return "air" end
    local top = layer.heights[x]
    if not top then return "air" end
    local dirt_lim = layer.dirt_limit[x] or (top + self.dirt_thickness)
    local stone_lim = layer.stone_limit[x] or (top + self.dirt_thickness + self.stone_thickness)

    if by == top then
        return "grass"
    elseif by > top and by <= dirt_lim then
        return "dirt"
    elseif by > dirt_lim and by <= stone_lim then
        return "stone"
    else
        return "air"
    end
end

function World:width() return self.width end
function World:height() return self.height end

-- optional helper: return the internal layer table for read-only inspection
function World:get_layer(z)
    return self.layers[z]
end

-- Draw a layer into the provided LOVE canvas.
-- Parameters:
--   z (number) - layer index (-1,0,1)
--   canvas (love.graphics.newCanvas) - target canvas to render into
--   blocks (table) - Blocks table containing color definitions (Blocks.grass, Blocks.dirt, Blocks.stone)
--   block_size (number) - pixel size of a block
--
function World:draw(z, canvas, blocks, block_size)
    if not canvas or not blocks or not block_size then return end
    local layer = self.layers[z]
    if not layer then return end

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.origin()

    -- draw entire procedural layer (tiles as rectangles)
    for x = 1, self.width do
        local top = layer.heights[x]
        if top then
            local px = (x - 1) * block_size

            -- grass / top
            local py = (top - 1) * block_size
            love.graphics.setColor(unpack(blocks.grass.color))
            love.graphics.rectangle("fill", px, py, block_size, block_size)

            -- dirt
            local dirt_limit = layer.dirt_limit[x] or math.min(self.height, top + self.dirt_thickness)
            dirt_limit = math.min(dirt_limit, self.height)
            love.graphics.setColor(unpack(blocks.dirt.color))
            for y = top + 1, dirt_limit do
                local dy = (y - 1) * block_size
                love.graphics.rectangle("fill", px, dy, block_size, block_size)
            end

            -- stone
            local stone_limit = layer.stone_limit[x] or math.min(self.height, top + self.dirt_thickness + self.stone_thickness)
            stone_limit = math.min(stone_limit, self.height)
            if dirt_limit + 1 <= stone_limit then
                love.graphics.setColor(unpack(blocks.stone.color))
                for y = dirt_limit + 1, stone_limit do
                    local dy = (y - 1) * block_size
                    love.graphics.rectangle("fill", px, dy, block_size, block_size)
                end
            end
        end
    end

    -- draw placed blocks overlay for this layer (if any)
    if self.placed and self.placed[z] then
        for x, column in pairs(self.placed[z]) do
            for y, blockName in pairs(column) do
                -- skip sentinel "__empty" (represents a removed procedural block)
                if blockName ~= "__empty" then
                    local px = (x - 1) * block_size
                    local py = (y - 1) * block_size
                    local color = nil
                    if Blocks[blockName] and Blocks[blockName].color then
                        color = Blocks[blockName].color
                    elseif blocks and blocks[blockName] and blocks[blockName].color then
                        color = blocks[blockName].color
                    end
                    if color then
                        love.graphics.setColor(unpack(color))
                    else
                        love.graphics.setColor(1, 1, 1, 1)
                    end
                    -- draw placed block visually identical to procedural blocks (no 1px border)
                    love.graphics.rectangle("fill", px, py, block_size, block_size)
                end
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas()
end

return World