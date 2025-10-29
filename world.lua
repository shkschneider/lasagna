-- World module — converted to an Object{} prototype (no inheritance).
-- World.tiles now store block prototypes (Blocks.grass / Blocks.dirt / Blocks.stone) or nil for air.
-- This eliminates the need for string-to-prototype resolution at draw time.
local Object = require("lib.object")
local noise = require("noise1d")
local Blocks = require("blocks") -- used for drawing block colors / block.draw
local log = require("lib.log")

local DEFAULTS = {
    WIDTH = 500,
    HEIGHT = 100,
    DIRT_THICKNESS = 10,
    STONE_THICKNESS = 10,
    LAYER_BASE_HEIGHTS = { [-1] = 20, [0] = 30, [1] = 40 },
    AMPLITUDE = { [-1] = 15, [0] = 10, [1] = 10 },
    FREQUENCY = { [-1] = 1/40, [0] = 1/50, [1] = 1/60 },
}

local World = Object {} -- prototype

-- init(self, seed)
function World.load(self, seed)
    self.seed = seed
    -- Use internal defaults
    self.width = DEFAULTS.WIDTH
    self.height = DEFAULTS.HEIGHT
    self.dirt_thickness = DEFAULTS.DIRT_THICKNESS
    self.stone_thickness = DEFAULTS.STONE_THICKNESS
    self.layer_base_heights = DEFAULTS.LAYER_BASE_HEIGHTS
    self.amplitude = DEFAULTS.AMPLITUDE
    self.frequency = DEFAULTS.FREQUENCY

    -- materialized tiles: tiles[z][x][y] = prototype table or nil == air
    self.layers = {}
    self.tiles = {}

    if self.seed ~= nil then math.randomseed(self.seed) end
    noise.init(self.seed)
    self:regenerate()

    log.info("World created with seed:", tostring(self.seed))
end

-- Backwards-compatible constructor
function World.new(seed)
    return World(seed)
end

-- regenerate procedural world into explicit tiles grid (clears any runtime edits)
-- Now stores prototypes (Blocks.grass/dirt/stone) instead of strings.
function World:regenerate()
    if self.seed ~= nil then math.randomseed(self.seed) end
    noise.init(self.seed)

    for z = -1, 1 do
        local layer = { heights = {}, dirt_limit = {}, stone_limit = {} }
        local tiles_for_layer = {}
        for x = 1, self.width do
            local n = noise.perlin1d(x * (self.frequency and self.frequency[z] or DEFAULTS.FREQUENCY[z]) + (z * 100))
            local base = (self.layer_base_heights and self.layer_base_heights[z]) or DEFAULTS.LAYER_BASE_HEIGHTS[z]
            local amp = (self.amplitude and self.amplitude[z]) or DEFAULTS.AMPLITUDE[z]
            local top = math.floor(base + amp * n)
            top = math.max(1, math.min(self.height - 1, top))

            local dirt_lim = math.min(self.height, top + self.dirt_thickness)
            local stone_lim = math.min(self.height, top + self.dirt_thickness + self.stone_thickness)

            layer.heights[x] = top
            layer.dirt_limit[x] = dirt_lim
            layer.stone_limit[x] = stone_lim

            -- materialize column x for this layer (store prototypes)
            tiles_for_layer[x] = {}
            for y = 1, self.height do
                local proto = nil
                if y == top then
                    proto = Blocks.grass
                elseif y > top and y <= dirt_lim then
                    proto = Blocks.dirt
                elseif y > dirt_lim and y <= stone_lim then
                    proto = Blocks.stone
                else
                    proto = nil -- air
                end
                tiles_for_layer[x][y] = proto
            end
        end

        self.layers[z] = layer
        self.tiles[z] = tiles_for_layer
    end
end

-- Return surface/top (row) for layer z at column x, or nil if out of range
function World:get_surface(z, x)
    if x < 1 or x > self.width then return nil end
    local tiles_z = self.tiles[z]
    if not tiles_z then return nil end
    for y = 1, self.height do
        local t = tiles_z[x][y]
        if t ~= nil then
            return y
        end
    end
    return nil
end

-- Compatibility helper: place a block only if the cell is empty (air)
-- returns true/false, msg
-- Accepts either prototype or string (string will be converted), stores prototype internally.
function World:place_block(z, x, y, block)
    if not z or not x or not y or not block then return false, "invalid parameters" end
    if x < 1 or x > self.width or y < 1 or y > self.height then return false, "out of bounds" end
    if not self.tiles[z] or not self.tiles[z][x] then return false, "internal tiles not initialized" end

    -- normalize block to prototype
    local proto = nil
    if type(block) == "string" then
        proto = Blocks[block]
        if not proto then return false, "unknown block name" end
    elseif type(block) == "table" then
        proto = block
    else
        return false, "invalid block type"
    end

    if self.tiles[z][x][y] ~= nil then return false, "cell not empty" end
    self.tiles[z][x][y] = proto
    log.info(string.format("World: placed block '%s' at z=%d x=%d y=%d", tostring(proto.name), z, x, y))
    return true
end

-- Unified setter: setting block to nil removes the block (air), setting to prototype or name places/overwrites.
function World:set_block(z, x, y, block)
    if not z or not x or not y then return false, "invalid parameters" end
    if x < 1 or x > self.width or y < 1 or y > self.height then return false, "out of bounds" end
    if not self.tiles[z] or not self.tiles[z][x] then return false, "internal tiles not initialized" end

    if block == "__empty" then block = nil end

    local proto = nil
    if type(block) == "string" then
        proto = Blocks[block]
        if not proto then return false, "unknown block name" end
    elseif type(block) == "table" then
        proto = block
    elseif block == nil then
        proto = nil
    else
        return false, "invalid block type"
    end

    local prev = self.tiles[z][x][y] -- may be nil or prototype
    if proto == nil then
        if prev == nil then
            return false, "nothing to remove"
        end
        self.tiles[z][x][y] = nil
        log.info(string.format("World: removed block at z=%d x=%d y=%d (was=%s)", z, x, y, tostring(prev and prev.name)))
        return true, "removed"
    else
        local action = (prev == nil) and "added" or "replaced"
        self.tiles[z][x][y] = proto
        log.info(string.format("World: %s block '%s' at z=%d x=%d y=%d (prev=%s)", action, tostring(proto.name), z, x, y, tostring(prev and prev.name)))
        return true, action
    end
end

-- get block type at (z, x, by)
-- returns: "out", "air" or prototype table
function World:get_block_type(z, x, by)
    if x < 1 or x > self.width or by < 1 or by > self.height then return "out" end
    if not self.tiles[z] or not self.tiles[z][x] then return "air" end
    local t = self.tiles[z][x][by]
    if t == nil then return "air" end
    return t
end

function World:width() return self.width end
function World:height() return self.height end
function World:get_layer(z) return self.layers[z] end

-- Draw a layer into the provided LOVE canvas by delegating tile drawing to Blocks.draw.
-- World.tiles store prototypes so Blocks.draw expects prototype.
function World:draw(z, canvas, blocks, block_size)
    if not canvas or not block_size then return end
    local tiles_z = self.tiles[z]
    if not tiles_z then return end

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.origin()

    for x = 1, self.width do
        local column = tiles_z[x]
        if column then
            for y = 1, self.height do
                local proto = column[y]
                if proto ~= nil then
                    Blocks.draw(proto, x, y, block_size, 0)
                end
            end
        end
    end

    love.graphics.setColor(1,1,1,1)
    love.graphics.setCanvas()
end

return World