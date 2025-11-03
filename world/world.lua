local Object = require("lib.object")
local noise = require("lib.noise")
local log = require("lib.log")
local Blocks = require("data.blocks")
local Player = require("entities.player")
local Drop = require("entities.drop")
local Layer = require("world.layer")
local Weather = require("world.weather")
local Lighting = require("lib.lighting")

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
    self.lighting = Lighting()
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

function World:update(dt)
    -- Update weather system
    if self.weather then
        self.weather:update(dt)
        
        -- Update ambient lighting based on time of day
        if self.lighting then
            local hours, minutes = self.weather:get_time_24h()
            local time_decimal = hours + (minutes / 60.0)
            
            -- Calculate ambient light level based on time
            -- Full brightness during day (7:00-17:00)
            -- Reduced brightness at night
            local ambient_level = 1.0
            if time_decimal >= 7 and time_decimal < 17 then
                ambient_level = 1.0  -- Full daylight
            elseif time_decimal >= 5 and time_decimal < 7 then
                -- Sunrise: 5:00-7:00
                local t = (time_decimal - 5) / 2
                ambient_level = 0.15 + (0.85 * t)
            elseif time_decimal >= 17 and time_decimal < 19 then
                -- Sunset: 17:00-19:00
                local t = (time_decimal - 17) / 2
                ambient_level = 1.0 - (0.85 * t)
            else
                -- Night time: very low ambient light
                ambient_level = 0.15
            end
            
            self.lighting:set_ambient_light(ambient_level)
        end
    end
    
    -- Update lighting system
    if self.lighting then
        -- Clear dynamic lights each frame
        self.lighting:clear_lights()
        
        -- Add player light source
        local player = self:player()
        if player then
            -- Player position is in world blocks, light at center of player
            local light_x = player.px + player.width / 2
            local light_y = player.py + player.height / 2
            self.lighting:add_light(light_x, light_y, player.z, 0.9, 12)
        end
        
        self.lighting:update(dt)
    end
    
    -- Entities handle their own update logic
    -- Use reverse iteration to safely remove entities during update
    for i = #self.entities, 1, -1 do
        local e = self.entities[i]
        if type(e.update) == "function" then
            local keep = e:update(dt, self, self:player())
            -- If update returns false, remove the entity
            if keep == false then
                table.remove(self.entities, i)
                log.debug(string.format("Removed entity at index %d", i))
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

function World:spawn_dropped_item(proto, px, py, z, count)
    if not proto then return false end
    count = count or 1
    local item = Drop(proto, px, py, z, count)
    table.insert(self.entities, item)
    log.info(string.format("Spawned dropped item '%s' x%d at (%.2f, %.2f, %d)",
        proto.name or "unknown", count, px, py, z))
    return true
end

function World:draw()
    -- Draw sky background
    if self.weather then
        self.weather:draw()
    end

    -- Calculate visible columns
    local left_col = math.floor(G.cx / C.BLOCK_SIZE)
    local right_col = math.ceil((G.cx + G.width) / C.BLOCK_SIZE) + 1
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
            layer:draw()
        end

        -- Draw dropped items on this layer before drawing player
        for _, e in ipairs(self.entities) do
            if e ~= self:player() and e.z == z and type(e.draw) == "function" then
                e:draw()
            end
        end

        if z == self:player().z then return end
    end
end

return World
