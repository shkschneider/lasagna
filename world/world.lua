-- World module — converted to an Object{} prototype (no inheritance).
-- World.tiles store block prototypes (Blocks.grass / Blocks.dirt / Blocks.stone) or nil for air.
-- This file owns environment queries and now owns per-layer canvases and partial-redraw helpers.
local Object = require("lib.object")
local noise = require("lib.noise")
local log = require("lib.log")
local Blocks = require("world.blocks")
local Player = require("entities.player")
local Movements = require("entities.movements")

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
    self.entities = {}

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

    self.entities = { Player() }
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

-- Optional per-world update hook; will be responsible for physics/contacts
function World.update(self, dt)
    if Blocks and type(Blocks.update) == "function" then Blocks.update(dt) end

    for _, e in ipairs(self.entities) do
        e.intent = e.intent or {}
        local intent = e.intent

        local MAX_SPEED = (e.max_speed ~= nil) and e.max_speed or Game.MAX_SPEED
        local accel = (e.move_accel ~= nil) and e.move_accel or Game.MOVE_ACCEL

        if intent.run then
            MAX_SPEED = Game.RUN_SPEED_MULT * MAX_SPEED
            accel = Game.RUN_ACCEL_MULT * accel
        end
        if intent.crouch or e.crouching then
            MAX_SPEED = math.min(MAX_SPEED, Game.CROUCH_MAX_SPEED)
        end
        if not e.on_ground then accel = accel * Game.AIR_ACCEL_MULT end

        local dir = 0
        if intent.left then dir = dir - 1 end
        if intent.right then dir = dir + 1 end

        local target_vx = dir * MAX_SPEED

        if dir ~= 0 then
            local use_accel = accel
            if e.crouching then use_accel = accel * 0.6 end
            if e.vx < target_vx then
                e.vx = math.min(target_vx, e.vx + use_accel * dt)
            elseif e.vx > target_vx then
                e.vx = math.max(target_vx, e.vx - use_accel * dt)
            end
        else
            if e.crouching then
                local dec = Game.CROUCH_DECEL * dt
                if math.abs(e.vx) <= dec then e.vx = 0 else e.vx = e.vx - (e.vx > 0 and 1 or -1) * dec end
            else
                if e.on_ground then
                    local dec = Game.GROUND_FRICTION * dt
                    if math.abs(e.vx) <= dec then e.vx = 0 else e.vx = e.vx - (e.vx > 0 and 1 or -1) * dec end
                else
                    local dec = Game.AIR_FRICTION * dt
                    if math.abs(e.vx) <= dec then e.vx = 0 else e.vx = e.vx - (e.vx > 0 and 1 or -1) * dec end
                end
            end
        end

        if intent.jump then
            if e.on_ground then
                e.vy = Game.JUMP_SPEED
                e.on_ground = false
            end
            e.intent.jump = false
        end

        e.vy = e.vy + Game.GRAVITY * dt

        local dx = e.vx * dt
        local dy = e.vy * dt

        if type(Movements.move) == "function" then
            Movements.move(e, dx, dy, self)
        else
            if type(self.move_entity) == "function" then
                self:move_entity(e, dx, dy)
            end
        end

        -- crouch/stand mechanics (kept here for now). Mark player's canvas dirty when posture changes.
        if intent.crouch then
            if not e.crouching then
                local height_diff = e.stand_height - e.crouch_height
                e.crouching = true
                e.py = e.py + height_diff
                e.height = e.crouch_height
                if type(e.canvas_dirty) ~= "nil" then e.canvas_dirty = true end
            end
        else
            if e.crouching then
                local height_diff = e.stand_height - e.crouch_height
                local new_py = e.py - height_diff
                local new_height = e.stand_height
                local left_col = math.floor(e.px + 1e-6)
                local right_col = math.floor(e.px + e.width - 1e-6)
                local can_stand = true
                for col = left_col, right_col do
                    for row = math.floor(new_py + 1e-6), math.floor(new_py + new_height - 1e-6) do
                        if self:is_solid(e.z, col, row) then
                            can_stand = false
                            break
                        end
                    end
                    if not can_stand then break end
                end
                if can_stand then
                    e.crouching = false
                    e.py = new_py
                    e.height = e.stand_height
                    if type(e.canvas_dirty) ~= "nil" then e.canvas_dirty = true end
                end
            end
        end
    end
end

-- Entity registration helpers
function World:add_entity(e)
    if not e then return end
    for _, v in ipairs(self.entities) do
        if v == e then return end
    end
    table.insert(self.entities, e)
end

function World:remove_entity(e)
    for i, v in ipairs(self.entities) do
        if v == e then
            table.remove(self.entities, i)
            return
        end
    end
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

-- Fallback world-side mover (kept for compatibility)
function World:move_entity(e, dx, dy)
    if dx ~= 0 then
        local desired_px = e.px + dx
        if desired_px < 1 then desired_px = 1 end
        if desired_px > math.max(1, Game.WORLD_WIDTH - e.width + 1) then desired_px = math.max(1, Game.WORLD_WIDTH - e.width + 1) end

        if desired_px > e.px then
            local right_now = math.floor(e.px + e.width - 1e-6)
            local right_desired = math.floor(desired_px + e.width - 1e-6)
            local top_row = math.floor(e.py + 1e-6)
            local bottom_row = math.floor(e.py + e.height - 1e-6)
            local blocked = false
            for col = right_now + 1, right_desired do
                if (col < 1 or col > Game.WORLD_WIDTH) then blocked = true desired_px = col - e.width break end
                for row = top_row, bottom_row do
                    if self:is_solid(e.z, col, row) then blocked = true desired_px = col - e.width break end
                end
                if blocked then break end
            end
            if not blocked then
                local left_col = math.floor(desired_px + 1e-6)
                local right_col = math.floor(desired_px + e.width - 1e-6)
                for col = left_col, right_col do
                    for row = top_row, bottom_row do
                        if self:is_solid(e.z, col, row) then desired_px = col - e.width blocked = true break end
                    end
                    if blocked then break end
                end
            end
            if blocked then e.vx = 0 end
            e.px = desired_px
        else
            local left_now = math.floor(e.px + 1e-6)
            local left_desired = math.floor(desired_px + 1e-6)
            local top_row = math.floor(e.py + 1e-6)
            local bottom_row = math.floor(e.py + e.height - 1e-6)
            local blocked = false
            for col = left_desired, left_now - 1 do
                if (col < 1 or col > Game.WORLD_WIDTH) then blocked = true desired_px = col + 1 break end
                for row = top_row, bottom_row do
                    if self:is_solid(e.z, col, row) then blocked = true desired_px = col + 1 break end
                end
                if blocked then break end
            end
            if not blocked then
                local left_col = math.floor(desired_px + 1e-6)
                local right_col = math.floor(desired_px + e.width - 1e-6)
                for col = left_col, right_col do
                    for row = top_row, bottom_row do
                        if self:is_solid(e.z, col, row) then desired_px = col + 1 blocked = true break end
                    end
                    if blocked then break end
                end
            end
            if blocked then e.vx = 0 end
            e.px = desired_px
        end
    end

    if dy ~= 0 then
        local desired_py = e.py + dy
        if desired_py < 1 then desired_py = 1 end
        if desired_py > math.max(1, Game.WORLD_HEIGHT - e.height + 1) then desired_py = math.max(1, Game.WORLD_HEIGHT - e.height + 1) end

        if desired_py > e.py then
            local top_row = math.floor(e.py + 1e-6)
            local bottom_now = math.floor(e.py + e.height - 1e-6)
            local bottom_desired = math.floor(desired_py + e.height - 1e-6)
            local left_col = math.floor(e.px + 1e-6)
            local right_col = math.floor(e.px + e.width - 1e-6)
            local blocked = false
            for row = bottom_now + 1, bottom_desired do
                if (row < 1 or row > Game.WORLD_HEIGHT) then blocked = true desired_py = row - e.height break end
                for col = left_col, right_col do
                    if self:is_solid(e.z, col, row) then blocked = true desired_py = row - e.height break end
                end
                if blocked then break end
            end
            if blocked then
                e.vy = 0
                e.on_ground = true
            else
                local top_row2 = math.floor(desired_py + 1e-6)
                local bottom_row2 = math.floor(desired_py + e.height - 1e-6)
                for row = top_row2, bottom_row2 do
                    for col = left_col, right_col do
                        if self:is_solid(e.z, col, row) then desired_py = row - e.height blocked = true break end
                    end
                    if blocked then break end
                end
                if blocked then
                    e.vy = 0
                    e.on_ground = true
                else
                    e.on_ground = false
                end
            end
            e.py = desired_py
        else
            local top_now = math.floor(e.py + 1e-6)
            local top_desired = math.floor(desired_py + 1e-6)
            local left_col = math.floor(e.px + 1e-6)
            local right_col = math.floor(e.px + e.width - 1e-6)
            local blocked = false
            for row = top_desired, top_now - 1 do
                if (row < 1 or row > Game.WORLD_HEIGHT) then blocked = true desired_py = row + 1 break end
                for col = left_col, right_col do
                    if self:is_solid(e.z, col, row) then blocked = true desired_py = row + 1 break end
                end
                if blocked then break end
            end
            if blocked then e.vy = 0 end
            e.py = desired_py
        end
    end
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

-- draw: full-scene draw (camera_x, canvases optional, player, block_size, screen_w, screen_h, debug)
-- If canvases not passed, draws using self.canvases
function World.draw(self, camera_x, canvases, player, block_size, screen_w, screen_h, debug)
    canvases = canvases or self.canvases
    player = player or (Game and Game.player and Game:player())
    block_size = block_size or (Game and Game.BLOCK_SIZE) or 16
    screen_w = screen_w or (Game and Game.screen_width) or (love.graphics.getWidth and love.graphics.getWidth())
    screen_h = screen_h or (Game and Game.screen_height) or (love.graphics.getHeight and love.graphics.getHeight())
    debug = (debug ~= nil) and debug or (Game and Game.debug)

    if not canvases then return end

    local player_z = player and player.z or 0
    for z = -1, player_z do
        local canvas = canvases[z]
        if canvas then
            love.graphics.push()
            love.graphics.origin()
            love.graphics.translate(-camera_x, 0)

            local alpha = 1
            if player and type(player.z) == "number" and z < player.z then
                local depth = player.z - z
                alpha = 1 - 0.25 * depth
                if alpha < 0 then alpha = 0 end
            end

            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.draw(canvas, 0, 0)
            love.graphics.pop()
            love.graphics.setColor(1,1,1,1)
        end

        if player and z == player_z then
            if player.draw then
                player:draw(block_size, camera_x)
            end
        end
    end

    love.graphics.origin()

    if player and player.drawInventory then
        player:drawInventory(screen_w, screen_h)
    end
    if player and player.drawGhost then
        player:drawGhost(self, camera_x, block_size)
    end
end

function World:get_layer(z) return self.layers[z] end
function World:width() return Game.WORLD_WIDTH end
function World:height() return Game.WORLD_HEIGHT end

return World