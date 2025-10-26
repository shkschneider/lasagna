-- World module — materialized tiles edition
-- - Procedural generation now writes an explicit tiles[z][x][y] grid (strings for block names, nil == air).
-- - set_block directly modifies tiles (so world tiles are mutable at runtime).
-- - get_block_type reads tiles first (nil => "air"), so reading/writing is straightforward:
--     world.tiles[z][x][y] = nil  -- remove block (air)
--     world.tiles[z][x][y] = "dirt" -- place block
-- - Kept compat helpers place_block / set_block for convenience and logging.
-- - World:draw now draws from the materialized tiles table.
--
local noise = require("noise1d")
local Blocks = require("blocks") -- used for drawing block colors
local log = require("lib.log")

local World = {}
World.__index = World

local DEFAULTS = {
    WIDTH = 500,
    HEIGHT = 100,
    DIRT_THICKNESS = 10,
    STONE_THICKNESS = 10,
    LAYER_BASE_HEIGHTS = { [-1] = 20, [0] = 30, [1] = 40 },
    AMPLITUDE = { [-1] = 15, [0] = 10, [1] = 10 },
    FREQUENCY = { [-1] = 1/40, [0] = 1/50, [1] = 1/60 },
}

local unpack = table.unpack or unpack or function(t)
    return t[1], t[2], t[3], t[4]
end

-- Create a new world
function World.new(seed, opts)
    opts = opts or {}
    local self = setmetatable({}, World)
    self.seed = seed
    self.width = opts.width or DEFAULTS.WIDTH
    self.height = opts.height or DEFAULTS.HEIGHT
    self.dirt_thickness = opts.dirt_thickness or DEFAULTS.DIRT_THICKNESS
    self.stone_thickness = opts.stone_thickness or DEFAULTS.STONE_THICKNESS
    self.layer_base_heights = opts.layer_base_heights or DEFAULTS.LAYER_BASE_HEIGHTS
    self.amplitude = opts.amplitude or DEFAULTS.AMPLITUDE
    self.frequency = opts.frequency or DEFAULTS.FREQUENCY

    -- materialized tiles: tiles[z][x][y] = blockName (string) or nil == air
    self.layers = {}   -- keep layer metadata (useful if you want to regenerate)
    self.tiles = {}    -- tiles[z] = { [x] = { [y] = blockName_or_nil } }

    if self.seed ~= nil then math.randomseed(self.seed) end
    noise.init(self.seed)
    self:regenerate()

    log.info("World created with seed:", tostring(self.seed))
    return self
end

-- regenerate procedural world into explicit tiles grid (clears any runtime edits)
-- If you want to preserve player edits across regen, you'll need to merge them back in afterwards.
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

            -- materialize column x for this layer
            tiles_for_layer[x] = {}
            for y = 1, self.height do
                local blockName = nil
                if y == top then
                    blockName = "grass"
                elseif y > top and y <= dirt_lim then
                    blockName = "dirt"
                elseif y > dirt_lim and y <= stone_lim then
                    blockName = "stone"
                else
                    blockName = nil -- air
                end
                tiles_for_layer[x][y] = blockName
            end
        end

        self.layers[z] = layer
        self.tiles[z] = tiles_for_layer
    end
end

-- Return surface/top (row) for layer z at column x, or nil if out of range
-- now simply scans the tiles grid for first non-nil block
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
function World:place_block(z, x, y, blockName)
    if not z or not x or not y or not blockName then return false, "invalid parameters" end
    if x < 1 or x > self.width or y < 1 or y > self.height then return false, "out of bounds" end
    if not self.tiles[z] or not self.tiles[z][x] then return false, "internal tiles not initialized" end
    if self.tiles[z][x][y] ~= nil then return false, "cell not empty" end
    self.tiles[z][x][y] = blockName
    log.info(string.format("World: placed block '%s' at z=%d x=%d y=%d", tostring(blockName), z, x, y))
    return true
end

-- Unified setter: setting blockName to nil removes the block (air), setting to string places/overwrites.
-- kept for compatibility: if blockName == "__empty" treat like nil (remove)
function World:set_block(z, x, y, blockName)
    if not z or not x or not y then return false, "invalid parameters" end
    if x < 1 or x > self.width or y < 1 or y > self.height then return false, "out of bounds" end
    if not self.tiles[z] or not self.tiles[z][x] then return false, "internal tiles not initialized" end

    if blockName == "__empty" then blockName = nil end

    local prev = self.tiles[z][x][y] -- may be nil (air) or string
    if blockName == nil then
        if prev == nil then
            return false, "nothing to remove"
        end
        self.tiles[z][x][y] = nil
        log.info(string.format("World: removed block at z=%d x=%d y=%d (was=%s)", z, x, y, tostring(prev)))
        return true, "removed"
    else
        -- place/overwrite
        local action = (prev == nil) and "added" or "replaced"
        self.tiles[z][x][y] = blockName
        log.info(string.format("World: %s block '%s' at z=%d x=%d y=%d (prev=%s)", action, tostring(blockName), z, x, y, tostring(prev)))
        return true, action
    end
end

-- get block type at (z, x, by)
-- returns: "out", "air" or blockName string
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

-- Draw a layer into the provided LOVE canvas by iterating the materialized tiles.
function World:draw(z, canvas, blocks, block_size)
    if not canvas or not blocks or not block_size then return end
    local tiles_z = self.tiles[z]
    if not tiles_z then return end

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.origin()

    for x = 1, self.width do
        local px = (x - 1) * block_size
        local column = tiles_z[x]
        if column then
            for y = 1, self.height do
                local blockName = column[y]
                if blockName ~= nil then
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
                        love.graphics.setColor(1,1,1,1)
                    end
                    love.graphics.rectangle("fill", px, py, block_size, block_size)
                end
            end
        end
    end

    love.graphics.setColor(1,1,1,1)
    love.graphics.setCanvas()
end

return World