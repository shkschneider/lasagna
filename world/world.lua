-- World module — converted to an Object{} prototype (no inheritance).
-- World.tiles store block prototypes (Blocks.grass / Blocks.dirt / Blocks.stone) or nil for air.
-- This file owns environment queries and now owns per-layer canvases and partial-redraw helpers.
local Object = require("lib.object")
local noise = require("lib.noise")
local log = require("lib.log")
local Blocks = require("world.blocks")

local World = Object {
    WIDTH = 500,
    HEIGHT = 100,
    DIRT_THICKNESS = 10,
    STONE_THICKNESS = 10,
    LAYER_BASE_HEIGHTS = { [-1] = 20, [0] = 30, [1] = 40 },
    AMPLITUDE = { [-1] = 15, [0] = 10, [1] = 10 },
    FREQUENCY = { [-1] = 1/40, [0] = 1/50, [1] = 1/60 },
}

function World:new(seed)
    self.seed = seed
    self.layers = {}
    self.tiles = {}

    -- canvases owned by the world (per-layer)
    self.canvases = {}

    if self.seed ~= nil then math.randomseed(self.seed) end
    noise.init(self.seed)
    self:load()

    log.info("World created with seed:", tostring(self.seed))
end

function World:load()
    if self.seed ~= nil then math.randomseed(self.seed) end
    noise.init(self.seed)

    -- Use Game globals for sizing/params
    for z = -1, 1 do
        local layer = { heights = {}, dirt_limit = {}, stone_limit = {} }
        local tiles_for_layer = {}
        for x = 1, Game.WORLD_WIDTH do
            local freq = (self.frequency and self.frequency[z]) or Game.FREQUENCY[z]
            local n = noise.perlin1d(x * freq + (z * 100))
            local base = (self.layer_base_heights and self.layer_base_heights[z]) or Game.LAYER_BASE_HEIGHTS[z]
            local amp = (self.amplitude and self.amplitude[z]) or Game.AMPLITUDE[z]
            local top = math.floor(base + amp * n)
            top = math.max(1, math.min(Game.WORLD_HEIGHT - 1, top))

            local dirt_lim = math.min(Game.WORLD_HEIGHT, top + Game.DIRT_THICKNESS)
            local stone_lim = math.min(Game.WORLD_HEIGHT, top + Game.DIRT_THICKNESS + Game.STONE_THICKNESS)

            layer.heights[x] = top
            layer.dirt_limit[x] = dirt_lim
            layer.stone_limit[x] = stone_lim

            tiles_for_layer[x] = {}
            for y = 1, Game.WORLD_HEIGHT do
                local proto = nil
                -- Blocks is expected to be available globally (main.lua sets _G.Blocks)
                if y == top then
                    proto = Blocks and Blocks.grass
                elseif y > top and y <= dirt_lim then
                    proto = Blocks and Blocks.dirt
                elseif y > dirt_lim and y <= stone_lim then
                    proto = Blocks and Blocks.stone
                else
                    proto = nil
                end
                tiles_for_layer[x][y] = proto
            end
        end

        self.layers[z] = layer
        self.tiles[z] = tiles_for_layer
    end
end

-- Create per-layer full-world canvases and store them on the World instance.
-- Also draws each layer into its canvas.
function World:create_canvases(block_size)
    block_size = block_size or Game.BLOCK_SIZE
    local canvas_w = Game.WORLD_WIDTH * block_size
    local canvas_h = Game.WORLD_HEIGHT * block_size
    self.canvases = self.canvases or {}

    for z = -1, 1 do
        -- replace existing canvas if present
        if self.canvases[z] and self.canvases[z].release then
            pcall(function() self.canvases[z]:release() end)
        end
        local canvas = love.graphics.newCanvas(canvas_w, canvas_h)
        canvas:setFilter("nearest", "nearest")
        self.canvases[z] = canvas
        -- draw full layer into canvas
        self:draw_layer(z, canvas, nil, block_size)
    end
end

-- Draw a single column (world column index) of a layer into its canvas.
-- This is used to avoid full-layer redraws on single-tile edits.
function World:draw_column(z, col, block_size)
    block_size = block_size or Game.BLOCK_SIZE
    if not self.canvases or not self.canvases[z] then return end
    if col < 1 or col > Game.WORLD_WIDTH then return end

    local canvas = self.canvases[z]
    local tiles_z = self.tiles[z]
    if not tiles_z then return end

    local px = (col - 1) * block_size
    -- Draw only the column area: use scissor to limit drawing region
    love.graphics.push()
    love.graphics.setCanvas(canvas)
    love.graphics.setScissor(px, 0, block_size, Game.WORLD_HEIGHT * block_size)
    -- clear the column region to transparent
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.origin()

    local column = tiles_z[col]
    if column then
        for row = 1, Game.WORLD_HEIGHT do
            local proto = column[row]
            if proto ~= nil then
                local py = (row - 1) * block_size
                if type(proto.draw) == "function" then
                    proto:draw(px, py, block_size)
                elseif proto.color and love and love.graphics then
                    local c = proto.color
                    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
                    love.graphics.rectangle("fill", px, py, block_size, block_size)
                    love.graphics.setColor(1,1,1,1)
                end
            end
        end
    end

    love.graphics.setScissor()
    love.graphics.setCanvas()
    love.graphics.pop()
end

-- Optional per-world update hook
function World.update(self, dt)
    if Blocks and type(Blocks.update) == "function" then Blocks.update(dt) end
end

-- Tile solidity check: treats stored prototype tables as authoritative
function World:is_solid(z, col, row)
    if col < 1 or col > Game.WORLD_WIDTH or row < 1 or row > Game.WORLD_HEIGHT then return false end
    local tz = self.tiles and self.tiles[z]
    if not tz then return false end
    local column = tz[col]
    if not column then return false end
    local t = column[row]
    if t == nil then return false end
    local proto = t
    if proto then
        if type(proto.is_solid) == "function" then return proto:is_solid() end
        if proto.solid ~= nil then return proto.solid end
    end
    return true
end

-- Return surface/top (row) for layer z at column x, or nil if out of range
function World:get_surface(z, x)
    if type(x) ~= "number" then return nil end
    if x < 1 or x > Game.WORLD_WIDTH then return nil end
    local tiles_z = self.tiles and self.tiles[z]
    if not tiles_z then return nil end
    for y = 1, Game.WORLD_HEIGHT do
        local t = tiles_z[x] and tiles_z[x][y]
        if t ~= nil then
            return y
        end
    end
    return nil
end

-- place_block kept for compatibility; it uses set_block internally
function World:place_block(z, x, y, block)
    return self:set_block(z, x, y, block)
end

-- Unified setter: setting block to nil removes the block (air), setting to prototype or name places/overwrites.
-- After a successful change we redraw only the affected column in the layer canvas.
function World:set_block(z, x, y, block)
    if not z or not x or not y then return false, "invalid parameters" end
    if x < 1 or x > Game.WORLD_WIDTH or y < 1 or y > Game.WORLD_HEIGHT then return false, "out of bounds" end
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

    local prev = self.tiles[z][x][y]
    if proto == nil then
        if prev == nil then
            return false, "nothing to remove"
        end
        self.tiles[z][x][y] = nil
        log.info(string.format("World: removed block at z=%d x=%d y=%d (was=%s)", z, x, y, tostring(prev and prev.name)))
        -- redraw affected column only
        if self.canvases and self.canvases[z] then self:draw_column(z, x, Game.BLOCK_SIZE) end
        return true, "removed"
    else
        local action = (prev == nil) and "added" or "replaced"
        self.tiles[z][x][y] = proto
        log.info(string.format("World: %s block '%s' at z=%d x=%d y=%d (prev=%s)", action, tostring(proto.name), z, x, y, tostring(prev and prev.name)))
        if self.canvases and self.canvases[z] then self:draw_column(z, x, Game.BLOCK_SIZE) end
        return true, action
    end
end

-- get block type at (z, x, by)
-- returns: "out", "air" or prototype table
function World:get_block_type(z, x, by)
    if x < 1 or x > Game.WORLD_WIDTH or by < 1 or by > Game.WORLD_HEIGHT then return "out" end
    if not self.tiles[z] or not self.tiles[z][x] then return "air" end
    local t = self.tiles[z][x][by]
    if t == nil then return "air" end
    return t
end

-- draw_layer: draw a single layer into provided canvas (legacy API)
function World.draw_layer(self, z, canvas, blocks, block_size)
    if not canvas or not block_size then return end
    local tiles_z = self.tiles[z]
    if not tiles_z then return end

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.origin()

    for col = 1, Game.WORLD_WIDTH do
        local column = tiles_z[col]
        if column then
            for row = 1, Game.WORLD_HEIGHT do
                local proto = column[row]
                if proto ~= nil then
                    local px = (col - 1) * block_size
                    local py = (row - 1) * block_size
                    if type(proto.draw) == "function" then
                        proto:draw(px, py, block_size)
                    elseif proto.color and love and love.graphics then
                        local c = proto.color
                        love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
                        love.graphics.rectangle("fill", px, py, block_size, block_size)
                        love.graphics.setColor(1,1,1,1)
                    end
                end
            end
        end
    end

    love.graphics.setColor(1,1,1,1)
    love.graphics.setCanvas()
end

-- draw: draws world layers with optional alpha based on player's Z position
-- Player is passed only for determining layer visibility/alpha, not for drawing
function World.draw(self, camera_x, canvases, player_z)
    canvases = canvases or self.canvases
    camera_x = camera_x or 0
    player_z = player_z or 0

    if not canvases then return end

    for z = -1, player_z do
        local canvas = canvases[z]
        if canvas then
            love.graphics.push()
            love.graphics.origin()
            love.graphics.translate(-camera_x, 0)

            local alpha = 1
            if z < player_z then
                local depth = player_z - z
                alpha = 1 - 0.25 * depth
                if alpha < 0 then alpha = 0 end
            end

            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.draw(canvas, 0, 0)
            love.graphics.pop()
            love.graphics.setColor(1,1,1,1)
        end
    end

    love.graphics.origin()
end

function World:get_layer(z) return self.layers[z] end
function World:width() return Game.WORLD_WIDTH end
function World:height() return Game.WORLD_HEIGHT end

return World