-- World module — converted to an Object{} prototype (no inheritance).
-- World.tiles store block prototypes (Blocks.grass / Blocks.dirt / Blocks.stone) or nil for air.
-- This file owns physics/collision for registered entities and provides both:
--  - draw_layer(z, canvas, blocks, block_size)  -- draws a single layer into a canvas
--  - draw(camera_x, canvases, player, block_size, screen_w, screen_h, debug) -- full-scene draw
local Object = require("lib.object")
local noise = require("lib.noise")
local Blocks = require("world.blocks") -- legacy/compat; prototypes are drawn directly now
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

-- constructor (instance initializer)
-- Called on the instance when a World instance is created (via World(...) or Object.new(World, ...))
function World:new(seed)
    self.seed = seed
    -- Use Game-provided defaults
    self.width = Game.WORLD_WIDTH
    self.height = Game.WORLD_HEIGHT
    self.dirt_thickness = Game.DIRT_THICKNESS
    self.stone_thickness = Game.STONE_THICKNESS
    self.layer_base_heights = Game.LAYER_BASE_HEIGHTS
    self.amplitude = Game.AMPLITUDE
    self.frequency = Game.FREQUENCY

    -- materialized tiles: tiles[z][x][y] = prototype table or nil == air
    self.layers = {}
    self.tiles = {}

    -- entities registered with the world (player, NPCs, etc.)
    self.entities = {}

    if self.seed ~= nil then math.randomseed(self.seed) end
    noise.init(self.seed)
    -- regenerate the world now that instance fields are set and methods are available
    self:load()

    log.info("World created with seed:", tostring(self.seed))
end

-- regenerate procedural world into explicit tiles grid (clears any runtime edits)
-- Now stores prototypes (Blocks.grass/dirt/stone) instead of strings.
function World:load()
    if self.seed ~= nil then math.randomseed(self.seed) end
    noise.init(self.seed)

    for z = -1, 1 do
        local layer = { heights = {}, dirt_limit = {}, stone_limit = {} }
        local tiles_for_layer = {}
        for x = 1, self.width do
            local freq = (self.frequency and self.frequency[z]) or Game.FREQUENCY[z]
            local n = noise.perlin1d(x * freq + (z * 100))
            local base = (self.layer_base_heights and self.layer_base_heights[z]) or Game.LAYER_BASE_HEIGHTS[z]
            local amp = (self.amplitude and self.amplitude[z]) or Game.AMPLITUDE[z]
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
                    proto = Blocks and Blocks.grass
                elseif y > top and y <= dirt_lim then
                    proto = Blocks and Blocks.dirt
                elseif y > dirt_lim and y <= stone_lim then
                    proto = Blocks and Blocks.stone
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

-- Note: the factory helper World.new (as a function returning Object.new(World, seed))
-- was removed because the prototype is callable and Object.new will invoke the prototype:new initializer.
-- Create World instances with either:
--   local w = World(seed)        -- callable prototype
--   local w = Object.new(World, seed)

-- Optional per-world update hook; will be responsible for physics/contacts
function World.update(self, dt)
    -- Update block prototypes if needed
    if Blocks and type(Blocks.update) == "function" then Blocks.update(dt) end

    -- Process each entity registered with the world
    for _, e in ipairs(self.entities) do
        -- ensure entity has intent table
        e.intent = e.intent or {}
        local intent = e.intent

        -- movement constants derived from Game and entity overrides (use entity fields if present)
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

        -- accelerate / decelerate horizontally
        if dir ~= 0 then
            local use_accel = accel
            if e.crouching then use_accel = accel * 0.6 end
            if e.vx < target_vx then
                e.vx = math.min(target_vx, e.vx + use_accel * dt)
            elseif e.vx > target_vx then
                e.vx = math.max(target_vx, e.vx - use_accel * dt)
            end
        else
            -- apply friction / deceleration
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

        -- jump intent: translate to vertical velocity if on_ground
        if intent.jump then
            if e.on_ground then
                e.vy = Game.JUMP_SPEED
                e.on_ground = false
            end
            -- consume the jump intent (one-shot)
            e.intent.jump = false
        end

        -- gravity
        e.vy = e.vy + Game.GRAVITY * dt

        -- integrate movement (axis-separated with collision resolution)
        local dx = e.vx * dt
        local dy = e.vy * dt

        self:move_entity(e, dx, dy)

        -- crouch/stand mechanics: entry is by holding crouch intent; standing should be validated by headroom
        if intent.crouch then
            if not e.crouching then
                -- enter crouch: lower height, keep feet in place
                local height_diff = e.stand_height - e.crouch_height
                e.crouching = true
                e.py = e.py + height_diff
                e.height = e.crouch_height
            end
        else
            if e.crouching then
                -- attempt to stand up: check for space above
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
    if col < 1 or col > self.width or row < 1 or row > self.height then return false end
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

-- Move an entity with axis-separated resolution against the tile grid.
-- e must have: px, py, width, height, vx, vy, z, on_ground
function World:move_entity(e, dx, dy)
    -- horizontal
    if dx ~= 0 then
        local desired_px = e.px + dx
        -- clamp to world bounds
        if desired_px < 1 then desired_px = 1 end
        if desired_px > math.max(1, self.width - e.width + 1) then desired_px = math.max(1, self.width - e.width + 1) end

        if desired_px > e.px then
            local right_now = math.floor(e.px + e.width - 1e-6)
            local right_desired = math.floor(desired_px + e.width - 1e-6)
            local top_row = math.floor(e.py + 1e-6)
            local bottom_row = math.floor(e.py + e.height - 1e-6)
            local blocked = false
            for col = right_now + 1, right_desired do
                if (col < 1 or col > self.width) then blocked = true desired_px = col - e.width break end
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
                if (col < 1 or col > self.width) then blocked = true desired_px = col + 1 break end
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

    -- vertical
    if dy ~= 0 then
        local desired_py = e.py + dy
        -- clamp world bounds
        if desired_py < 1 then desired_py = 1 end
        if desired_py > math.max(1, self.height - e.height + 1) then desired_py = math.max(1, self.height - e.height + 1) end

        if desired_py > e.py then
            -- moving down
            local top_row = math.floor(e.py + 1e-6)
            local bottom_now = math.floor(e.py + e.height - 1e-6)
            local bottom_desired = math.floor(desired_py + e.height - 1e-6)
            local left_col = math.floor(e.px + 1e-6)
            local right_col = math.floor(e.px + e.width - 1e-6)
            local blocked = false
            for row = bottom_now + 1, bottom_desired do
                if (row < 1 or row > self.height) then blocked = true desired_py = row - e.height break end
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
            -- moving up
            local top_now = math.floor(e.py + 1e-6)
            local top_desired = math.floor(desired_py + 1e-6)
            local left_col = math.floor(e.px + 1e-6)
            local right_col = math.floor(e.px + e.width - 1e-6)
            local blocked = false
            for row = top_desired, top_now - 1 do
                if (row < 1 or row > self.height) then blocked = true desired_py = row + 1 break end
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
    if x < 1 or x > self.width then return nil end
    local tiles_z = self.tiles and self.tiles[z]
    if not tiles_z then return nil end
    for y = 1, self.height do
        local t = tiles_z[x] and tiles_z[x][y]
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

-- draw_layer: draw a single layer into provided canvas (legacy single-layer API)
-- signature kept compatible: (self, z, canvas, blocks, block_size)
-- blocks argument is ignored; prototypes draw themselves directly.
function World.draw_layer(self, z, canvas, blocks, block_size)
    if not canvas or not block_size then return end
    local tiles_z = self.tiles[z]
    if not tiles_z then return end

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.origin()

    for col = 1, self.width do
        local column = tiles_z[col]
        if column then
            for row = 1, self.height do
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

-- draw: full-scene draw (camera_x, canvases, player, block_size, screen_w, screen_h, debug)
function World.draw(self, camera_x, canvases, player, block_size, screen_w, screen_h, debug)
    canvases = canvases or (Game and Game.canvases)
    player = player or (Game and Game.player)
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
            -- draw player on top of the player's layer
            if player.draw then
                player:draw(block_size, camera_x)
            end
        end
    end

    love.graphics.origin()

    -- HUD: inventory and ghost preview
    if player and player.drawInventory then
        player:drawInventory(screen_w, screen_h)
    end
    if player and player.drawGhost then
        player:drawGhost(self, camera_x, block_size)
    end
end

function World:width() return self.width end
function World:height() return self.height end
function World:get_layer(z) return self.layers[z] end

return World