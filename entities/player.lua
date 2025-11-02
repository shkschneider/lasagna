local Object = require("lib.object")
local Blocks = require("world.blocks")
local Physics = require("world.physics")
local log = require("lib.log")

-- Player state enums
local MovementState = {
    GROUNDED = "GROUNDED",
    AIRBORNE = "AIRBORNE",
}

local Stance = {
    STANDING = "STANDING",
    CROUCHING = "CROUCHING",
}

local Player = Object {}

function Player:new()
    self.px = 50
    self.py = 1
    self.z  = 0
    self.width = 1
    self.height = 2
    self.stand_height = self.height
    self.crouch_height = self.height / 2
    self.vx = 0
    self.vy = 0

    -- State system
    self.movement_state = MovementState.AIRBORNE
    self.stance = Stance.STANDING

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
    -- Initialize with 64 of each block type
    local block_types = { Blocks.grass, Blocks.dirt, Blocks.stone }
    for i, block in ipairs(block_types) do
        if i <= self.inventory.slots then
            self.inventory.items[i] = {
                proto = block,
                count = C.MAX_STACK,
                data = {}
            }
        end
    end
    self.intent = { left = false, right = false, jump = false, crouch = false, run = false }
end

function Player:is_grounded()
    return self.movement_state == MovementState.GROUNDED
end

function Player:is_crouching()
    return self.stance == Stance.CROUCHING
end

function Player:keypressed(key)
    if key == "q" then
        self.z = math.max(C.LAYER_MIN, self.z - 1)
        local top = G.world:get_surface(self.z, math.floor(self.px)) or (C.WORLD_HEIGHT - 1)
        self.py = top - self.height
        self.vy = 0
        log.info(string.format("Layer: %d", self.z))
    elseif key == "e" then
        self.z = math.min(C.LAYER_MAX, self.z + 1)
        local top = G.world:get_surface(self.z, math.floor(self.px)) or (C.WORLD_HEIGHT - 1)
        self.py = top - self.height
        self.vy = 0
        log.info(string.format("Layer: %d", self.z))
    elseif key == "space" or key == "up" then
        self.intent.jump = true
    end
end

function Player:update(dt)
    -- Handle continuous input (movement keys)
    self.intent.left = love.keyboard.isDown("a") or love.keyboard.isDown("left")
    self.intent.right = love.keyboard.isDown("d") or love.keyboard.isDown("right")
    self.intent.crouch = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    self.intent.run = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

    -- Physics and movement
    local MAX_SPEED = C.MAX_SPEED
    local accel = C.MOVE_ACCEL
    if self.intent.run then
        MAX_SPEED = C.RUN_SPEED_MULT * MAX_SPEED
        accel = C.RUN_ACCEL_MULT * accel
    end
    if self:is_crouching() then
        MAX_SPEED = math.min(MAX_SPEED, C.CROUCH_MAX_SPEED)
    end
    if not self:is_grounded() then
        accel = accel * C.AIR_ACCEL_MULT
    end

    local dir = 0
    if self.intent.left then dir = dir - 1 end
    if self.intent.right then dir = dir + 1 end
    local target_vx = dir * MAX_SPEED

    if dir ~= 0 then
        local use_accel = accel
        if self:is_crouching() then use_accel = accel * 0.6 end
        if self.vx < target_vx then
            self.vx = math.min(target_vx, self.vx + use_accel * dt)
        elseif self.vx > target_vx then
            self.vx = math.max(target_vx, self.vx - use_accel * dt)
        end
    else
        if self:is_crouching() then
            local dec = C.CROUCH_DECEL * dt
            if math.abs(self.vx) <= dec then self.vx = 0 else self.vx = self.vx - (self.vx > 0 and 1 or -1) * dec end
        else
            if self:is_grounded() then
                local dec = C.GROUND_FRICTION * dt
                if math.abs(self.vx) <= dec then self.vx = 0 else self.vx = self.vx - (self.vx > 0 and 1 or -1) * dec end
            else
                local dec = C.AIR_FRICTION * dt
                if math.abs(self.vx) <= dec then self.vx = 0 else self.vx = self.vx - (self.vx > 0 and 1 or -1) * dec end
            end
        end
    end

    if self.intent.jump then
        if self:is_grounded() then
            self.vy = C.JUMP_SPEED
            self.movement_state = MovementState.AIRBORNE
        end
        self.intent.jump = false
    end

    self.vy = self.vy + C.GRAVITY * dt
    local dx = self.vx * dt
    local dy = self.vy * dt
    Physics.move(self, dx, dy, G.world)

    -- Handle stance (crouching/standing)
    if self.intent.crouch then
        if self.stance == Stance.STANDING then
            local height_diff = self.stand_height - self.crouch_height
            self.stance = Stance.CROUCHING
            self.py = self.py + height_diff
            self.height = self.crouch_height
        end
    else
        if self.stance == Stance.CROUCHING then
            local height_diff = self.stand_height - self.crouch_height
            local new_py = self.py - height_diff
            local new_height = self.stand_height
            local left_col = math.floor(self.px + C.EPS)
            local right_col = math.floor(self.px + self.width - C.EPS)
            local can_stand = true
            for col = left_col, right_col do
                for row = math.floor(new_py + C.EPS), math.floor(new_py + new_height - C.EPS) do
                    if G.world:is_solid(self.z, col, row) then
                        can_stand = false
                        break
                    end
                end
                if not can_stand then break end
            end
            if can_stand then
                self.stance = Stance.STANDING
                self.py = new_py
                self.height = self.stand_height
            end
        end
    end
end

function Player:draw()
    local sx = (self.px - 1) * C.BLOCK_SIZE - G.cx
    local sy = (self.py - 1) * C.BLOCK_SIZE
    love.graphics.rectangle("fill", sx, sy, self.width * C.BLOCK_SIZE, self.height * C.BLOCK_SIZE)
end

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

function Player:drawInventory()
    local total_width = self.inventory.slots * self.inventory.ui.slot_size + (self.inventory.slots - 1) * self.inventory.ui.padding
    local x0 = (G.width - total_width) / 2
    local y0 = G.height - self.inventory.ui.slot_size - 20
    local bg_margin = 8
    love.graphics.setColor(0,0,0,self.inventory.ui.background_alpha)
    love.graphics.rectangle("fill", x0 - bg_margin, y0 - bg_margin, total_width + bg_margin*2, self.inventory.ui.slot_size + bg_margin*2, 6, 6)
    for i = 1, self.inventory.slots do
        local sx = x0 + (i-1)*(self.inventory.ui.slot_size + self.inventory.ui.padding)
        local sy = y0
        love.graphics.setColor(0.12,0.12,0.12,1)
        love.graphics.rectangle("fill", sx, sy, self.inventory.ui.slot_size, self.inventory.ui.slot_size, 4, 4)
        local inner_pad = 8
        local cube_x, cube_y = sx + inner_pad, sy + inner_pad
        local cube_w, cube_h = self.inventory.ui.slot_size - inner_pad*2, self.inventory.ui.slot_size - inner_pad*2
        local item = self.inventory.items[i]
        -- Handle new inventory format: { proto, count, data }
        local proto = item and (item.proto or item)
        local count = item and item.count
        if proto and proto.color then
            local r,g,b,a = unpack(proto.color)
            if r and r > 1 then r,g,b,a = r/255, (g or 0)/255, (b or 0)/255, (a or 255)/255 end
            love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
            love.graphics.rectangle("fill", cube_x, cube_y, cube_w, cube_h, 3, 3)
            love.graphics.setColor(0,0,0,0.6)
            love.graphics.rectangle("line", cube_x + 0.5, cube_y + 0.5, cube_w - 1, cube_h - 1, 2, 2)
        else
            love.graphics.rectangle("fill", cube_x, cube_y, cube_w, cube_h, 3, 3)
        end
        -- Draw count if present
        if count and count > 1 then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(tostring(count), sx + 4, sy + self.inventory.ui.slot_size - 16)
        end
        love.graphics.setColor(0,0,0,0.6)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", sx + 0.5, sy + 0.5, self.inventory.ui.slot_size - 1, self.inventory.ui.slot_size - 1, 4, 4)
        if i == self.inventory.selected then
            love.graphics.setColor(1, 0.84, 0, 1)
            love.graphics.setLineWidth(self.inventory.ui.border_thickness)
            love.graphics.rectangle("line", sx + 1, sy + 1, self.inventory.ui.slot_size - 2, self.inventory.ui.slot_size - 2, 4, 4)
            love.graphics.setLineWidth(1)
        end
    end
    love.graphics.setColor(1,1,1,1)
end

function Player:drawGhost()
    -- Always show ghost block, even when no item is selected
    local total_width = self.inventory.slots * self.inventory.ui.slot_size + (self.inventory.slots - 1) * self.inventory.ui.padding
    local x0 = (G.width - total_width) / 2
    local y0 = G.height - self.inventory.ui.slot_size - 20
    local bg_margin = 8
    local inv_top = y0 - bg_margin
    
    -- Don't show ghost if mouse is over inventory
    local mx, my = love.mouse.getPosition()
    if my >= inv_top then return end
    
    -- Convert mouse screen position to world position
    local world_px = mx + G.cx
    local col = math.floor(world_px / C.BLOCK_SIZE) + 1
    local row = math.floor(my / C.BLOCK_SIZE) + 1
    row = math.max(1, math.min(C.WORLD_HEIGHT, row))
    
    -- Convert world grid position back to screen position
    local px = (col - 1) * C.BLOCK_SIZE - G.cx
    local py = (row - 1) * C.BLOCK_SIZE
    
    -- Draw ghost outline
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px + 0.5, py + 0.5, C.BLOCK_SIZE - 1, C.BLOCK_SIZE - 1)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function Player:placeAtMouse(mx, my, z_override)
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then mouse_x, mouse_y = love.mouse.getPosition() end
    local inv = self.inventory
    local selected = inv.selected or 1
    local item = inv.items and inv.items[selected]
    if not item then return false, "no item selected" end

    -- Handle new inventory format: { proto, count, data }
    local proto = item.proto or item
    local count = item.count or 1

    if count <= 0 then return false, "no items left" end

    local world_px = mouse_x + G.cx
    local col = math.floor(world_px / C.BLOCK_SIZE) + 1
    local row = math.floor(mouse_y / C.BLOCK_SIZE) + 1
    row = math.max(1, math.min(C.WORLD_HEIGHT, row))
    -- Only allow editing on current layer
    local z = self.z
    local target = G.world:get_block_type(z, col, row)
    if target ~= "air" then return false, "target not empty", z end
    local touches_existing = false
    for dx = -1, 1 do
        for dy = -1, 1 do
            if not (dx == 0 and dy == 0) then
                local nx, ny = col + dx, row + dy
                if ny >= 1 and ny <= C.WORLD_HEIGHT then
                    local neigh = G.world:get_block_type(z, nx, ny)
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
    local ok, action = G.world:set_block(z, col, row, proto)

    -- Decrement count on successful placement
    if ok and item.count then
        item.count = item.count - 1
        if item.count <= 0 then
            inv.items[selected] = nil
        end
    end

    return ok, action, z
end

function Player:removeAtMouse(mx, my, z_override)
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then mouse_x, mouse_y = love.mouse.getPosition() end
    local world_px = mouse_x + G.cx
    local col = math.floor(world_px / C.BLOCK_SIZE) + 1
    local row = math.floor(mouse_y / C.BLOCK_SIZE) + 1
    row = math.max(1, math.min(C.WORLD_HEIGHT, row))
    -- Only allow editing on current layer
    local z = self.z
    local t = G.world:get_block_type(z, col, row)
    if not t or t == "air" or t == "out" then
        return false, "nothing to remove", z
    end
    local ok, msg = G.world:set_block(z, col, row, nil)
    if ok then
        log.info(string.format("Removed block at z=%d, col=%d, row=%d", z, col, row))
        return true, msg, z
    end
    local ok2, msg2 = G.world:set_block(z, col, row, "__empty")
    if ok2 then
        log.info(string.format("Marked procedural block removed at z=%d, col=%d, row=%d", z, col, row))
        return true, msg2, z
    end
    return false, "failed to remove block", z
end

return Player
