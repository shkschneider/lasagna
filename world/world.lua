local Object = require("lib.object")
local noise = require("lib.noise")
local log = require("lib.log")
local Blocks = require("world.blocks")
local Player = require("entities.player")
local Movements = require("entities.movements")
local Layer = require("world.layer")

local World = Object {
    player = function (self)
        return self.entities[1]
    end,
}

function World:new(seed)
    assert(seed)
    self.seed = seed
    self.layers = {}
    self.entities = {}
end

function World:load()
    assert(self.seed)
    math.randomseed(self.seed)
    noise.init(self.seed)
    local spawn_x = 50
    for z = C.LAYER_MIN, C.LAYER_MAX do
        self.layers[z] = Layer(z)
        local freq = (self.frequency and self.frequency[z]) or C.FREQUENCY[z]
        local base = (self.layer_base_heights and self.layer_base_heights[z]) or C.LAYER_BASE_HEIGHTS[z]
        local amp = (self.amplitude and self.amplitude[z]) or C.AMPLITUDE[z]
        self.layers[z]:generate_terrain_range(spawn_x - 50, spawn_x + 50, freq, base, amp)
    end
    -- player
    self.entities = { Player() }
    log.info(string.format("World[%d] loaded", self.seed))
end

function World.update(self, dt)
    if type(Blocks.update) == "function" then Blocks.update(dt) end
    for _, e in ipairs(self.entities) do
        e.intent = e.intent or {}
        local intent = e.intent
        local MAX_SPEED = (e.max_speed ~= nil) and e.max_speed or C.MAX_SPEED
        local accel = (e.move_accel ~= nil) and e.move_accel or C.MOVE_ACCEL
        if intent.run then
            MAX_SPEED = C.RUN_SPEED_MULT * MAX_SPEED
            accel = C.RUN_ACCEL_MULT * accel
        end
        if intent.crouch or e.crouching then
            MAX_SPEED = math.min(MAX_SPEED, C.CROUCH_MAX_SPEED)
        end
        if not e.on_ground then accel = accel * C.AIR_ACCEL_MULT end
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
                local dec = C.CROUCH_DECEL * dt
                if math.abs(e.vx) <= dec then e.vx = 0 else e.vx = e.vx - (e.vx > 0 and 1 or -1) * dec end
            else
                if e.on_ground then
                    local dec = C.GROUND_FRICTION * dt
                    if math.abs(e.vx) <= dec then e.vx = 0 else e.vx = e.vx - (e.vx > 0 and 1 or -1) * dec end
                else
                    local dec = C.AIR_FRICTION * dt
                    if math.abs(e.vx) <= dec then e.vx = 0 else e.vx = e.vx - (e.vx > 0 and 1 or -1) * dec end
                end
            end
        end
        if intent.jump then
            if e.on_ground then
                e.vy = C.JUMP_SPEED
                e.on_ground = false
            end
            e.intent.jump = false
        end
        e.vy = e.vy + C.GRAVITY * dt
        local dx = e.vx * dt
        local dy = e.vy * dt
        Movements.move(e, dx, dy, self)
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

function World:is_solid(z, col, row)
    if row < 1 or row > C.WORLD_HEIGHT then return false end
    -- Remove horizontal bounds check - terrain can extend infinitely
    local layer = self.layers[z]
    assert(layer)
    local column = layer.tiles[col]
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

function World:get_surface(z, x)
    assert(type(z) == "number")
    assert(type(x) == "number")
    local layer = self.layers and self.layers[z]
    assert(layer)

    local col = math.floor(x)

    -- Generate terrain if it doesn't exist
    if not layer.tiles[col] then
        local freq = (self.frequency and self.frequency[z]) or C.FREQUENCY[z]
        local base = (self.layer_base_heights and self.layer_base_heights[z]) or C.LAYER_BASE_HEIGHTS[z]
        local amp = (self.amplitude and self.amplitude[z]) or C.AMPLITUDE[z]
        layer:generate_column(col, freq, base, amp)
    end

    -- Find the surface (first non-nil block from top)
    for y = 1, C.WORLD_HEIGHT do
        local t = layer.tiles[col] and layer.tiles[col][y]
        if t ~= nil then
            return y
        end
    end
    return nil
end

function World:set_block(z, x, y, block)
    if not z or not x or not y then return false, "invalid parameters" end
    if y < 1 or y > C.WORLD_HEIGHT then return false, "out of bounds" end
    -- Remove horizontal bounds check - allow infinite terrain
    -- Ensure column exists before setting
    local layer = self.layers[z]
    if not layer then return false, "layer not initialized" end
    if not layer.tiles[x] then
        -- Generate this column if it doesn't exist
        local freq = (self.frequency and self.frequency[z]) or C.FREQUENCY[z]
        local base = (self.layer_base_heights and self.layer_base_heights[z]) or C.LAYER_BASE_HEIGHTS[z]
        local amp = (self.amplitude and self.amplitude[z]) or C.AMPLITUDE[z]
        layer:generate_column(x, freq, base, amp)
    end
    if not layer.tiles[x] then return false, "internal tiles not initialized" end
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
    local prev = layer.tiles[x][y]
    if proto == nil then
        if prev == nil then
            return false, "nothing to remove"
        end
        layer.tiles[x][y] = nil
        log.info(string.format("World: removed block at z=%d x=%d y=%d (was=%s)", z, x, y, tostring(prev and prev.name)))
        return true, "removed"
    else
        local action = (prev == nil) and "added" or "replaced"
        layer.tiles[x][y] = proto
        log.info(string.format("World: %s block '%s' at z=%d x=%d y=%d (prev=%s)", action, tostring(proto.name), z, x, y, tostring(prev and prev.name)))
        return true, action
    end
end

function World:get_block_type(z, x, by)
    if by < 1 or by > C.WORLD_HEIGHT then return "out" end
    -- Remove horizontal bounds check - allow infinite terrain
    local layer = self.layers[z]
    if not layer or not layer.tiles[x] then return "air" end
    local t = layer.tiles[x][by]
    if t == nil then return "air" end
    return t
end

function World:draw(cx)
    -- Calculate visible columns
    local left_col = math.floor(cx / C.BLOCK_SIZE)
    local right_col = math.ceil((cx + G.width) / C.BLOCK_SIZE) + 1
    -- Draw each layer
    for z = C.LAYER_MIN, C.LAYER_MAX do
        local layer = self.layers[z]
        if layer then
            -- Generate terrain for visible columns if needed
            local freq = (self.frequency and self.frequency[z]) or C.FREQUENCY[z]
            local base = (self.layer_base_heights and self.layer_base_heights[z]) or C.LAYER_BASE_HEIGHTS[z]
            local amp = (self.amplitude and self.amplitude[z]) or C.AMPLITUDE[z]
            for col = left_col, right_col do
                if not layer.tiles[col] then
                    layer:generate_column(col, freq, base, amp)
                end
            end
            layer:draw(cx, G.width, G.height)
        end
        if z == self:player().z then return end
    end
end

return World
