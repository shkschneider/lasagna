-- Player implemented as an Object (uses lib.object).
-- Player follows a simple LOVE-like API:
--   player = Player()           -- create with defaults
--   player:update(dt)           -- reads keyboard state itself, uses Game.world
--   player:draw(block_size, camera_x)
local Object = require("lib.object")
local Blocks = require("blocks")
local log = require("lib.log")

local EPS = 1e-6

local Player = Object {} -- create prototype, attach methods below

-- init() no opts table anymore — use defaults internal to the prototype
function Player.load(self)
    -- defaults
    self.px = 50
    self.py = 1
    self.z  = 0

    self.width = 1
    self.height = 2
    self.stand_height = self.height
    self.crouch_height = 1
    self.crouching = false
    self.on_ground = false

    self.vx = 0
    self.vy = 0

    local slots = 9
    self.inventory = {
        slots = slots,
        selected = 1,
        items = {},
        ui = {
            slot_size = 48,
            padding = 6,
            border_thickness = 3,
            background_alpha = 0.6,
        },
    }

    -- populate inventory deterministically and safely:
    local items_source = nil
    if type(Blocks) == "table" and type(Blocks.list) == "function" then
        items_source = Blocks.list()
    else
        local names = {}
        for k, v in pairs(Blocks) do
            if type(k) == "string" and type(v) == "table" then
                table.insert(names, k)
            end
        end
        table.sort(names)
        items_source = {}
        for _, name in ipairs(names) do
            local b = Blocks[name]
            if type(b) == "table" then
                if not b.name then b.name = name end
                table.insert(items_source, b)
            end
        end
    end

    for _, b in ipairs(items_source) do
        if #self.inventory.items >= self.inventory.slots then break end
        table.insert(self.inventory.items, b)
    end

    self.ghost = { mx = 0, my = 0, z = self.z }
end

local function tile_solid(world, z, col, row)
    if not world then return false end
    if type(col) ~= "number" or type(row) ~= "number" then return false end
    if col < 1 or col > world.width or row < 1 or row > world.height then return false end
    local tz = world.tiles and world.tiles[z]
    if not tz then return false end
    local column = tz[col]
    if not column then return false end
    local t = column[row]
    if t == nil then return false end
    -- t may be a prototype table (preferred) or a legacy string; handle both.
    local blk = nil
    if type(t) == "string" then
        blk = Blocks[t]
    else
        blk = t
    end
    if blk then
        if type(blk.is_solid) == "function" then return blk:is_solid() end
        if blk.solid ~= nil then return blk.solid end
    end
    return true
end

local function sign(x)
    if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end
end

-- Update reads input directly (WASD / arrows), jump handled on keypress (love.keypressed)
function Player:update(dt)
    -- read controls directly
    local left = love.keyboard.isDown("a") or love.keyboard.isDown("left")
    local right = love.keyboard.isDown("d") or love.keyboard.isDown("right")
    local crouch = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    local run = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

    -- Handle crouch/stand state and adjust height/py appropriately.
    -- When crouching, lower the player's top (py increases) so feet stay in place.
    -- When standing, attempt to rise if there's room above.
    local world = Game.world
    if crouch then
        if not self.crouching then
            -- enter crouch
            self.crouching = true
            self.py = self.py + (self.stand_height - self.crouch_height)
            self.height = self.crouch_height
        end
    else
        if self.crouching then
            -- attempt to stand up: check for space above
            local height_diff = self.stand_height - self.crouch_height
            local new_py = self.py - height_diff
            local new_height = self.stand_height
            local left_col = math.floor(self.px + EPS)
            local right_col = math.floor(self.px + self.width - EPS)
            local can_stand = true
            for col = left_col, right_col do
                for row = math.floor(new_py + EPS), math.floor(new_py + new_height - EPS) do
                    if tile_solid(world, self.z, col, row) then
                        can_stand = false
                        break
                    end
                end
                if not can_stand then break end
            end
            if can_stand then
                self.crouching = false
                self.py = new_py
                self.height = self.stand_height
            else
                -- remain crouched
            end
        end
    end

    -- movement constants
    local MAX_SPEED = Game.MAX_SPEED
    local accel = Game.MOVE_ACCEL
    if run then
        MAX_SPEED = Game.RUN_SPEED_MULT * MAX_SPEED
        accel = Game.RUN_ACCEL_MULT * accel
    end
    if self.crouching then
        MAX_SPEED = math.min(MAX_SPEED, Game.CROUCH_MAX_SPEED)
    end
    if not self.on_ground then accel = accel * Game.AIR_ACCEL_MULT end

    local dir = 0
    if left then dir = dir - 1 end
    if right then dir = dir + 1 end

    if self.crouching then run = false end

    local target_vx = dir * MAX_SPEED
    if self.crouching then
        if target_vx > 0 then target_vx = math.min(target_vx, Game.CROUCH_MAX_SPEED) end
        if target_vx < 0 then target_vx = math.max(target_vx, -Game.CROUCH_MAX_SPEED) end
    end

    if dir ~= 0 then
        local use_accel = accel
        if self.crouching then use_accel = accel * 0.6 end
        if self.vx < target_vx then
            self.vx = math.min(target_vx, self.vx + use_accel * dt)
        elseif self.vx > target_vx then
            self.vx = math.max(target_vx, self.vx - use_accel * dt)
        end
    else
        if self.crouching then
            local dec = Game.CROUCH_DECEL * dt
            if math.abs(self.vx) <= dec then self.vx = 0 else self.vx = self.vx - sign(self.vx) * dec end
        else
            if self.on_ground then
                local dec = Game.GROUND_FRICTION * dt
                if math.abs(self.vx) <= dec then self.vx = 0 else self.vx = self.vx - sign(self.vx) * dec end
            else
                local dec = Game.AIR_FRICTION * dt
                if math.abs(self.vx) <= dec then self.vx = 0 else self.vx = self.vx - sign(self.vx) * dec end
            end
        end
    end

    -- gravity
    self.vy = self.vy + Game.GRAVITY * dt

    -- integrate axis-separated movement with collision against Game.world
    -- horizontal
    local desired_px = self.px + self.vx * dt
    if world and world.width then
        local min_px = 1
        local max_px = math.max(1, world.width - self.width + 1)
        if desired_px < min_px then desired_px = min_px end
        if desired_px > max_px then desired_px = max_px end
    end

    if math.abs(desired_px - self.px) > EPS then
        if desired_px > self.px then
            local right_now = math.floor(self.px + self.width - EPS)
            local right_desired = math.floor(desired_px + self.width - EPS)
            local top_row = math.floor(self.py + EPS)
            local bottom_row = math.floor(self.py + self.height - EPS)
            local blocked = false
            for col = right_now + 1, right_desired do
                if world and world.width and (col < 1 or col > world.width) then blocked = true desired_px = col - self.width break end
                for row = top_row, bottom_row do
                    if tile_solid(world, self.z, col, row) then blocked = true desired_px = col - self.width break end
                end
                if blocked then break end
            end
            if not blocked then
                local left_col = math.floor(desired_px + EPS)
                local right_col = math.floor(desired_px + self.width - EPS)
                for col = left_col, right_col do
                    for row = top_row, bottom_row do
                        if tile_solid(world, self.z, col, row) then desired_px = col - self.width blocked = true break end
                    end
                    if blocked then break end
                end
            end
            if blocked then self.vx = 0 end
            self.px = desired_px
        else
            local left_now = math.floor(self.px + EPS)
            local left_desired = math.floor(desired_px + EPS)
            local top_row = math.floor(self.py + EPS)
            local bottom_row = math.floor(self.py + self.height - EPS)
            local blocked = false
            for col = left_desired, left_now - 1 do
                if world and world.width and (col < 1 or col > world.width) then blocked = true desired_px = col + 1 break end
                for row = top_row, bottom_row do
                    if tile_solid(world, self.z, col, row) then blocked = true desired_px = col + 1 break end
                end
                if blocked then break end
            end
            if not blocked then
                local left_col = math.floor(desired_px + EPS)
                local right_col = math.floor(desired_px + self.width - EPS)
                for col = left_col, right_col do
                    for row = top_row, bottom_row do
                        if tile_solid(world, self.z, col, row) then desired_px = col + 1 blocked = true break end
                    end
                    if blocked then break end
                end
            end
            if blocked then self.vx = 0 end
            self.px = desired_px
        end
    end

    -- vertical
    local desired_py = self.py + self.vy * dt
    if world and world.height then
        local min_py = 1
        local max_py = math.max(1, world.height - self.height + 1)
        if desired_py < min_py then desired_py = min_py end
        if desired_py > max_py then desired_py = max_py end
    end

    if math.abs(desired_py - self.py) > EPS then
        if desired_py > self.py then
            local top_row = math.floor(self.py + EPS)
            local bottom_now = math.floor(self.py + self.height - EPS)
            local bottom_desired = math.floor(desired_py + self.height - EPS)
            local left_col = math.floor(self.px + EPS)
            local right_col = math.floor(self.px + self.width - EPS)
            local blocked = false
            for row = bottom_now + 1, bottom_desired do
                if world and world.height and (row < 1 or row > world.height) then blocked = true desired_py = row - self.height break end
                for col = left_col, right_col do
                    if tile_solid(world, self.z, col, row) then blocked = true desired_py = row - self.height break end
                end
                if blocked then break end
            end
            if blocked then
                self.vy = 0
                self.on_ground = true
            else
                local top_row2 = math.floor(desired_py + EPS)
                local bottom_row2 = math.floor(desired_py + self.height - EPS)
                for row = top_row2, bottom_row2 do
                    for col = left_col, right_col do
                        if tile_solid(world, self.z, col, row) then desired_py = row - self.height blocked = true break end
                    end
                    if blocked then break end
                end
                if blocked then
                    self.vy = 0
                    self.on_ground = true
                else
                    self.on_ground = false
                end
            end
            self.py = desired_py
        else
            local top_now = math.floor(self.py + EPS)
            local top_desired = math.floor(desired_py + EPS)
            local left_col = math.floor(self.px + EPS)
            local right_col = math.floor(self.px + self.width - EPS)
            local blocked = false
            for row = top_desired, top_now - 1 do
                if world and world.height and (row < 1 or row > world.height) then blocked = true desired_py = row + 1 break end
                for col = left_col, right_col do
                    if tile_solid(world, self.z, col, row) then blocked = true desired_py = row + 1 break end
                end
                if blocked then break end
            end
            if blocked then self.vy = 0 end
            self.py = desired_py
        end
    end

    -- clamp horizontally
    if Game.WORLD_WIDTH then
        local max_x = Game.WORLD_WIDTH - self.width + 1
        if self.px < 1 then self.px = 1 end
        if self.px > max_x then self.px = max_x end
    end
end

-- Draw uses Game.BLOCK_SIZE and Game.camera_x
function Player:draw(block_size, camera_x)
    block_size = block_size or Game.BLOCK_SIZE
    camera_x = camera_x or 0

    local px = (self.px - 1) * block_size - camera_x
    local py = (self.py - 1) * block_size
    love.graphics.push()
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill", px, py, self.width * block_size, self.height * block_size)
    love.graphics.pop()
end

-- Mouse wheel: change hotbar slot
function Player:wheelmoved(dx, dy)
    if not dy or dy == 0 then return end
    local inv = self.inventory
    if dy > 0 then
        inv.selected = inv.selected - 1
        if inv.selected < 1 then inv.selected = inv.slots end
    else
        inv.selected = inv.selected + 1
        if inv.selected > inv.slots then inv.selected = 1 end
    end
end

-- Draw inventory bar centered bottom
function Player:drawInventory(screen_w, screen_h)
    local inv = self.inventory
    local ui = inv.ui
    local total_slots = inv.slots
    local slot_w, slot_h = ui.slot_size, ui.slot_size
    local padding = ui.padding
    local total_width = total_slots * slot_w + (total_slots - 1) * padding
    local x0 = (screen_w - total_width) / 2
    local y0 = screen_h - slot_h - 20
    local bg_margin = 8

    love.graphics.setColor(0,0,0,ui.background_alpha)
    love.graphics.rectangle("fill", x0 - bg_margin, y0 - bg_margin, total_width + bg_margin*2, slot_h + bg_margin*2, 6, 6)

    for i = 1, total_slots do
        local sx = x0 + (i-1)*(slot_w + padding)
        local sy = y0
        love.graphics.setColor(0.12,0.12,0.12,1)
        love.graphics.rectangle("fill", sx, sy, slot_w, slot_h, 4, 4)

        local inner_pad = 8
        local cube_x, cube_y = sx + inner_pad, sy + inner_pad
        local cube_w, cube_h = slot_w - inner_pad*2, slot_h - inner_pad*2

        local item = inv.items[i]
        if item and item.color then
            love.graphics.setColor(table.unpack(item.color))
            love.graphics.rectangle("fill", cube_x, cube_y, cube_w, cube_h, 3, 3)
            love.graphics.setColor(0,0,0,0.6)
            love.graphics.rectangle("line", cube_x + 0.5, cube_y + 0.5, cube_w - 1, cube_h - 1, 2, 2)
        else
            love.graphics.setColor(0.75,0.75,0.75,1)
            love.graphics.rectangle("fill", cube_x, cube_y, cube_w, cube_h, 3, 3)
        end

        love.graphics.setColor(0,0,0,0.6)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", sx + 0.5, sy + 0.5, slot_w - 1, slot_h - 1, 4, 4)

        if i == inv.selected then
            love.graphics.setColor(1, 0.84, 0, 1)
            love.graphics.setLineWidth(ui.border_thickness)
            love.graphics.rectangle("line", sx + 1, sy + 1, slot_w - 2, slot_h - 2, 4, 4)
            love.graphics.setLineWidth(1)
        end
    end

    love.graphics.setColor(1,1,1,1)
end

function Player:drawGhost(world, camera_x, block_size)
    camera_x = camera_x or 0
    block_size = block_size or Game.BLOCK_SIZE

    local inv = self.inventory
    local selected = inv.selected or 1
    local item = inv.items and inv.items[selected]
    if not item or not item.color then return end

    local screen_w, screen_h = love.graphics.getWidth(), love.graphics.getHeight()
    local ui = inv.ui
    local total_slots = inv.slots
    local slot_w = ui.slot_size
    local slot_h = ui.slot_size
    local padding = ui.padding
    local total_width = total_slots * slot_w + (total_slots - 1) * padding
    local x0 = (screen_w - total_width) / 2
    local y0 = screen_h - slot_h - 20
    local bg_margin = 8
    local inv_top = y0 - bg_margin

    local mx, my = love.mouse.getPosition()
    if my >= inv_top then return end

    local world_px = mx + camera_x
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(my / block_size) + 1

    col = math.max(1, math.min(Game.WORLD_WIDTH, col))
    row = math.max(1, math.min(Game.WORLD_HEIGHT, row))

    local px = (col - 1) * block_size - camera_x
    local py = (row - 1) * block_size

    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px + 0.5, py + 0.5, block_size - 1, block_size - 1)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1,1,1,1)
end

function Player:placeAtMouse(world, camera_x, block_size, mx, my, z_override)
    if not world then return false, "no world" end
    camera_x = camera_x or 0
    block_size = block_size or Game.BLOCK_SIZE
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then mouse_x, mouse_y = love.mouse.getPosition() end

    local inv = self.inventory
    local selected = inv.selected or 1
    local item = inv.items and inv.items[selected]
    if not item then return false, "no item selected" end

    local world_px = mouse_x + camera_x
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(mouse_y / block_size) + 1

    col = math.max(1, math.min(Game.WORLD_WIDTH, col))
    row = math.max(1, math.min(Game.WORLD_HEIGHT, row))

    local z = z_override or self.z

    local target = world:get_block_type(z, col, row)
    if target ~= "air" then return false, "target not empty", z end

    -- require touching an existing block on same layer (8-neighborhood)
    local touches_existing = false
    for dx = -1, 1 do
        for dy = -1, 1 do
            if not (dx == 0 and dy == 0) then
                local nx, ny = col + dx, row + dy
                if nx >= 1 and nx <= Game.WORLD_WIDTH and ny >= 1 and ny <= Game.WORLD_HEIGHT then
                    local neigh = world:get_block_type(z, nx, ny)
                    if neigh and neigh ~= "air" and neigh ~= "out" then
                        touches_existing = true
                        break
                    end
                end
            end
        end
        if touches_existing then break end
    end

    if not touches_existing then
        return false, "must touch an existing block on the same layer", z
    end

    -- item is already a prototype; world:set_block accepts prototype or name
    local ok, action = world:set_block(z, col, row, item)
    return ok, action, z
end

function Player:removeAtMouse(world, camera_x, block_size, mx, my, z_override)
    if not world then return false, "no world" end
    camera_x = camera_x or 0
    block_size = block_size or Game.BLOCK_SIZE
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then mouse_x, mouse_y = love.mouse.getPosition() end

    local world_px = mouse_x + camera_x
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(mouse_y / block_size) + 1

    col = math.max(1, math.min(Game.WORLD_WIDTH, col))
    row = math.max(1, math.min(Game.WORLD_HEIGHT, row))

    if z_override then
        local z = z_override
        local ok, msg = world:set_block(z, col, row, nil)
        if ok then return true, msg, z end
        local ok2, msg2 = world:set_block(z, col, row, "__empty")
        if ok2 then return true, msg2, z end
        return false, "nothing to remove", nil
    end

    local layer_order = {1, 0, -1}
    for _, z in ipairs(layer_order) do
        local t = world:get_block_type(z, col, row)
        if t and t ~= "air" and t ~= "out" then
            local ok, msg = world:set_block(z, col, row, nil)
            if ok then
                log.info(string.format("Removed block at z=%d, col=%d, row=%d (overlay)", z, col, row))
                return true, msg, z
            end
            local ok2, msg2 = world:set_block(z, col, row, "__empty")
            if ok2 then
                log.info(string.format("Marked procedural block removed at z=%d, col=%d, row=%d", z, col, row))
                return true, msg2, z
            end
            return false, "failed to remove block at target layer", z
        end
    end

    return false, "nothing to remove", nil
end

return Player