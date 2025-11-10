local Object = require("lib.object")
local noise = require("lib.noise")
local log = require("lib.log")
local Blocks = require("data.blocks")
local Player = require("entities.player")
local Drop = require("entities.drop")
local Layer = require("world.layer")
local Weather = require("world.weather")

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
    self.weather = Weather()
end

function World:load()
    assert(self.seed)
    math.randomseed(self.seed)
    noise.init(self.seed)
    local spawn_x = 100  -- 50 * 2 to account for 2x2 subdivision
    for z = C.LAYER_MIN, C.LAYER_MAX do
        self.layers[z] = Layer(z)
        local freq = C.layer_frequency(z)
        local base = C.ground_level(z)
        local amp = C.layer_amplitude(z)
        self.layers[z]:generate_terrain_range(spawn_x - 100, spawn_x + 100, freq, base, amp)  -- 50 * 2
    end
    -- player
    self.entities = { Player() }
    log.info(string.format("World[%d] loaded", self.seed))
end

function World:update(dt)
    -- Update weather system
    if self.weather then
        self.weather:update(dt)
    end

    -- Entities handle their own update logic
    -- Use reverse iteration to safely remove entities during update
    for i = #self.entities, 1, -1 do
        local e = self.entities[i]
        if type(e.update) == "function" then
            local keep = e:update(dt, self, self:player())
            -- If update returns false, remove the entity
            if keep == false then
                if e.name then
                    log.debug(string.format("Removing drop '%s' at x=%d y=%d z=%d", e.name, e.px, e.py, e.z))
                end
                table.remove(self.entities, i)
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
        local freq = C.layer_frequency(z)
        local base = C.ground_level(z)
        local amp = C.layer_amplitude(z)
        local generated = layer:generate_column(col, freq, base, amp)
        if generated then
            layer:mark_dirty()
        end
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
        local freq = C.layer_frequency(z)
        local base = C.ground_level(z)
        local amp = C.layer_amplitude(z)
        local generated = layer:generate_column(x, freq, base, amp)
        if generated then
            layer:mark_dirty()
        end
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
        -- Check if trying to remove bedrock (indestructible)
        if prev and prev.name == "bedrock" then
            return false, "bedrock is indestructible"
        end
        layer.tiles[x][y] = nil
        layer:mark_dirty()  -- Mark layer as dirty when block changes
        log.debug(string.format("Removed block '%s' at x=%d y=%d z=%d", tostring(prev and prev.name), x, y, z))
        return true, "removed"
    else
        local action = (prev == nil) and "added" or "replaced"
        layer.tiles[x][y] = proto
        layer:mark_dirty()  -- Mark layer as dirty when block changes
        log.debug(string.format("Set block '%s' at x=%d y=%d z=%d", tostring(proto.name), x, y, z))
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

function World:spawn_dropped_item(proto, px, py, z, count)
    if not proto then return false end
    count = count or 1
    local item = Drop(proto, px, py, z, count)
    table.insert(self.entities, item)
    log.debug(string.format("Spawned drop '%s' at x=%d y=%d z=%d", proto.name or "?", px, py, z))
    return true
end

function World:draw()
    -- Draw sky background
    if self.weather then
        self.weather:draw()
    end

    -- Calculate visible columns
    local cx = G.camera:get_x()
    local left_col = math.floor(cx / C.BLOCK_SIZE)
    local right_col = math.ceil((cx + G.width) / C.BLOCK_SIZE) + 1
    -- Draw each layer (just terrain, no entities yet)
    for z = C.LAYER_MIN, C.LAYER_MAX do
        local layer = self.layers[z]
        if layer then
            -- Generate terrain for visible columns if needed
            local freq = C.layer_frequency(z)
            local base = C.ground_level(z)
            local amp = C.layer_amplitude(z)
            for col = left_col, right_col do
                if not layer.tiles[col] then
                    layer:generate_column(col, freq, base, amp)
                end
            end
            -- Don't mark dirty here - let canvas boundary check handle redraws
            layer:draw()
        end

        -- Stop drawing layers after player's layer
        if z == self:player().z then return end
    end
end

function World:draw_entities()
    -- Draw entities on each layer up to player's layer
    for z = C.LAYER_MIN, C.LAYER_MAX do
        -- Draw dropped items and other entities on this layer
        for _, e in ipairs(self.entities) do
            if e ~= self:player() and e.z == z and type(e.draw) == "function" then
                e:draw()
            end
        end

        if z == self:player().z then return end
    end
end

function World:draw_drops()
    -- Draw only drops on each layer up to player's layer
    for z = C.LAYER_MIN, C.LAYER_MAX do
        for _, e in ipairs(self.entities) do
            if e ~= self:player() and e.z == z and e.proto and type(e.draw) == "function" then
                e:draw()
            end
        end

        if z == self:player().z then return end
    end
end

function World:draw_other_entities()
    -- Draw entities that are not drops or player on each layer up to player's layer
    for z = C.LAYER_MIN, C.LAYER_MAX do
        for _, e in ipairs(self.entities) do
            if e ~= self:player() and e.z == z and not e.proto and type(e.draw) == "function" then
                e:draw()
            end
        end

        if z == self:player().z then return end
    end
end

return World
