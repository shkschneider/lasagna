-- Player module (movement + AABB collisions, hotbar UI, ghost preview, placement/removal)
-- Assumes global Game table and Game.* constants exist.
--
local Player = {}
Player.__index = Player

local Blocks = require("blocks")
local log = require("lib.log")

local EPS = 1e-6

local function sign(x)
    if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end
end

local function tile_solid(world, z, col, row)
    if not world then return false end
    local t = world:get_block_type(z, col, row)
    if not t then return false end
    return (t ~= "air" and t ~= "out")
end

-- Constructor
function Player.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Player)
    self.px = opts.px or 50
    self.py = opts.py or 0
    self.z  = opts.z  or 0
    self.vx = 0
    self.vy = 0

    self.width = opts.width or 1
    self.height = opts.height or 2
    self.stand_height = self.height
    self.crouch_height = 1
    self.crouching = false
    self.on_ground = false

    -- Inventory / HUD
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
        }
    }
    for name, block in pairs(Blocks) do
        if #self.inventory.items >= self.inventory.slots then break end
        table.insert(self.inventory.items, block)
    end

    return self
end

-- Attempt to stand (expand upward keeping bottom aligned)
local function try_stand(self, world)
    local desired_h = self.stand_height
    if self.height == desired_h then return true end
    local new_py = self.py - (desired_h - self.height)

    local left_col = math.floor(self.px + EPS)
    local right_col = math.floor(self.px + self.width - EPS)
    local top_row = math.floor(new_py + EPS)
    local bottom_row = math.floor(new_py + desired_h - EPS)

    local world_w, world_h = Game.WORLD_WIDTH, Game.WORLD_HEIGHT
    if world_w and (left_col < 1 or right_col > world_w) then return false end
    if world_h and (top_row < 1 or bottom_row > world_h) then return false end

    for r = top_row, bottom_row do
        for c = left_col, right_col do
            if tile_solid(world, self.z, c, r) then return false end
        end
    end

    self.py = new_py
    self.height = desired_h
    self.crouching = false
    return true
end

local function do_crouch(self)
    if self.height == self.crouch_height then return end
    local old_bottom = self.py + self.height
    self.height = self.crouch_height
    self.py = old_bottom - self.height
    self.crouching = true
end

-- Update: input, movement, gravity, collisions
-- input = { left=bool, right=bool, jump=bool, crouch=bool, run=bool }
function Player:update(dt, world, input)
    input = input or {}
    local crouch_input = input.crouch or false
    local run_input = input.run or false

    if crouch_input then
        do_crouch(self)
    else
        if self.crouching then
            if not try_stand(self, world) then
                crouch_input = true
            end
        end
    end

    local dir = 0
    if input.left then dir = dir - 1 end
    if input.right then dir = dir + 1 end

    if self.crouching then run_input = false end

    -- Movement constants (use Game.* directly)
    local MAX_SPEED = Game.MAX_SPEED
    local accel = Game.MOVE_ACCEL
    if run_input then
        MAX_SPEED = Game.MAX_SPEED * Game.RUN_SPEED_MULT
        accel = accel * Game.RUN_ACCEL_MULT
    end
    if not self.on_ground then accel = accel * Game.AIR_ACCEL_MULT end

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

    -- Gravity
    self.vy = self.vy + Game.GRAVITY * dt

    -- Collision helpers
    local world_w, world_h = Game.WORLD_WIDTH, Game.WORLD_HEIGHT
    local z = self.z

    local function horiz_span_px(px)
        local left_col = math.floor(px + EPS)
        local right_col = math.floor(px + self.width - EPS)
        return left_col, right_col
    end
    local function vert_span_py(py, use_h)
        local h = use_h or self.height
        local top_row = math.floor(py + EPS)
        local bottom_row = math.floor(py + h - EPS)
        return top_row, bottom_row
    end

    -- Horizontal integration + collision
    local desired_px = self.px + self.vx * dt
    if world_w then
        local min_px = 1
        local max_px = math.max(1, world_w - self.width + 1)
        if desired_px < min_px then desired_px = min_px end
        if desired_px > max_px then desired_px = max_px end
    end

    if math.abs(desired_px - self.px) > EPS then
        if desired_px > self.px then
            local _, right_now = horiz_span_px(self.px)
            local _, right_desired = horiz_span_px(desired_px)
            local top_row, bottom_row = vert_span_py(self.py)
            local blocked = false
            for col = right_now + 1, right_desired do
                if world_w and (col < 1 or col > world_w) then blocked = true desired_px = col - self.width break end
                for row = top_row, bottom_row do
                    if tile_solid(world, z, col, row) then blocked = true desired_px = col - self.width break end
                end
                if blocked then break end
            end
            if not blocked then
                local left_col, right_col = horiz_span_px(desired_px)
                for col = left_col, right_col do
                    for row = top_row, bottom_row do
                        if tile_solid(world, z, col, row) then desired_px = col - self.width blocked = true break end
                    end
                    if blocked then break end
                end
            end
            if blocked then self.vx = 0 end
            self.px = desired_px
        else
            local left_now = math.floor(self.px + EPS)
            local left_desired = math.floor(desired_px + EPS)
            local top_row, bottom_row = vert_span_py(self.py)
            local blocked = false
            for col = left_desired, left_now - 1 do
                if world_w and (col < 1 or col > world_w) then blocked = true desired_px = col + 1 break end
                for row = top_row, bottom_row do
                    if tile_solid(world, z, col, row) then blocked = true desired_px = col + 1 break end
                end
                if blocked then break end
            end
            if not blocked then
                local left_col, right_col = horiz_span_px(desired_px)
                for col = left_col, right_col do
                    for row = top_row, bottom_row do
                        if tile_solid(world, z, col, row) then desired_px = col + 1 blocked = true break end
                    end
                    if blocked then break end
                end
            end
            if blocked then self.vx = 0 end
            self.px = desired_px
        end
    end

    -- Vertical integration + collision
    local desired_py = self.py + self.vy * dt
    if world_h then
        local min_py = 1
        local max_py = math.max(1, world_h - self.height + 1)
        if desired_py < min_py then desired_py = min_py end
        if desired_py > max_py then desired_py = max_py end
    end

    if math.abs(desired_py - self.py) > EPS then
        if desired_py > self.py then
            local top_row, bottom_now = vert_span_py(self.py)
            local _, bottom_desired = vert_span_py(desired_py)
            local left_col, right_col = horiz_span_px(self.px)
            local blocked = false
            for row = bottom_now + 1, bottom_desired do
                if world_h and (row < 1 or row > world_h) then blocked = true desired_py = row - self.height break end
                for col = left_col, right_col do
                    if tile_solid(world, z, col, row) then blocked = true desired_py = row - self.height break end
                end
                if blocked then break end
            end
            if blocked then
                self.vy = 0
                self.on_ground = true
            else
                local top_row2, bottom_row2 = vert_span_py(desired_py)
                for row = top_row2, bottom_row2 do
                    for col = left_col, right_col do
                        if tile_solid(world, z, col, row) then desired_py = row - self.height blocked = true break end
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
            local left_col, right_col = horiz_span_px(self.px)
            local blocked = false
            for row = top_desired, top_now - 1 do
                if world_h and (row < 1 or row > world_h) then blocked = true desired_py = row + 1 break end
                for col = left_col, right_col do
                    if tile_solid(world, z, col, row) then blocked = true desired_py = row + 1 break end
                end
                if blocked then break end
            end
            if blocked then self.vy = 0 end
            self.py = desired_py
        end
    end

    -- clamp horizontally
    local max_x = Game.WORLD_WIDTH - self.width + 1
    if self.px < 1 then self.px = 1 end
    if self.px > max_x then self.px = max_x end
end

-- Draw player: plain white rectangle
function Player:draw(block_size, camera_x)
    block_size = block_size or Game.BLOCK_SIZE
    camera_x = camera_x or 0
    local px = (self.px - 1) * block_size - camera_x
    local py = (self.py - 1) * block_size
    love.graphics.push()
    love.graphics.setColor(1, 1, 1, 1)
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

-- Ghost preview: simple white border (no fill)
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

-- Place at mouse (returns ok, msg, z_changed)
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

    local target_type = world:get_block_type(z, col, row)
    if target_type ~= "air" then return false, "target not empty", z end

    local blockName = item.name
    for k, v in pairs(Blocks) do if v == item then blockName = k break end end
    if not blockName then return false, "unknown block type", z end

    local ok, action = world:set_block(z, col, row, blockName)
    return ok, action, z
end

-- Remove at mouse (returns ok, msg, z_changed)
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