-- Simple World module (pure logic + optional drawing helper)
-- Responsibilities:
--  - generate per-layer surface heights and dirt/stone limits
--  - provide small query API (get_surface, get_block_type, width/height)
--  - provide a drawing helper: World:draw(z, canvas, blocks, block_size)
--    (the draw helper uses LÖVE's love.graphics to render a layer into a canvas)
--
-- Usage:
--   local World = require("world")
--   local w = World.new(seed, opts)
--   w:regenerate()
--   local top = w:get_surface(0, 12)
--   local t = w:get_block_type(0, 12, 35)
--   -- to render a layer into a canvas (main.lua passes Blocks and block size)
--   w:draw(0, someCanvas, Blocks, 16)
--
local noise = require("noise1d")

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

    -- initialize noise and generate
    if self.seed ~= nil then
        math.randomseed(self.seed)
    end
    noise.init(self.seed)
    self:regenerate()
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
    end
end

-- return surface/top (row number) for layer z at column x, or nil if out of range
function World:get_surface(z, x)
    if x < 1 or x > self.width then return nil end
    local layer = self.layers[z]
    if not layer then return nil end
    return layer.heights[x]
end

-- get block type at (z, x, by)
-- by = block-row (1..height), x = column
-- returns: "out" (out of world bounds), "air", "grass", "dirt", "stone"
function World:get_block_type(z, x, by)
    if x < 1 or x > self.width or by < 1 or by > self.height then
        return "out"
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
-- This helper uses love.graphics and therefore couples this module to LÖVE when used.
-- It intentionally mirrors the previous rendering behaviour that existed in main.lua.
function World:draw(z, canvas, blocks, block_size)
    if not canvas or not blocks or not block_size then return end
    local layer = self.layers[z]
    if not layer then return end

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.origin()

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

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas()
end

return World