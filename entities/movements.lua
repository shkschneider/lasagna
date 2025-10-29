-- entities/physics.lua
-- Reusable axis-separated movement implementation for entities.
-- Split into small local helpers: move_right, move_left, move_down, move_up for clarity.
--
-- Usage:
--   local Physics = require("entities.physics")
--   Entity.move = Physics.move
--
-- self (entity) must expose: px, py, width, height, vx, vy, z, on_ground
-- world must expose: is_solid(z, col, row), width, height

local Physics = {}

-- Move right helper: attempts to set self.px to desired_px while resolving collisions.
local function move_right(self, desired_px, world)
    -- clamp world bounds
    if desired_px < 1 then desired_px = 1 end
    if desired_px > math.max(1, world.width - self.width + 1) then desired_px = math.max(1, world.width - self.width + 1) end

    local right_now = math.floor(self.px + self.width - 1e-6)
    local right_desired = math.floor(desired_px + self.width - 1e-6)
    local top_row = math.floor(self.py + 1e-6)
    local bottom_row = math.floor(self.py + self.height - 1e-6)
    local blocked = false

    for col = right_now + 1, right_desired do
        if (col < 1 or col > world.width) then
            blocked = true
            desired_px = col - self.width
            break
        end
        for row = top_row, bottom_row do
            if world:is_solid(self.z, col, row) then
                blocked = true
                desired_px = col - self.width
                break
            end
        end
        if blocked then break end
    end

    if not blocked then
        local left_col = math.floor(desired_px + 1e-6)
        local right_col = math.floor(desired_px + self.width - 1e-6)
        for col = left_col, right_col do
            for row = top_row, bottom_row do
                if world:is_solid(self.z, col, row) then
                    desired_px = col - self.width
                    blocked = true
                    break
                end
            end
            if blocked then break end
        end
    end

    if blocked then self.vx = 0 end
    self.px = desired_px
end

-- Move left helper.
local function move_left(self, desired_px, world)
    -- clamp world bounds
    if desired_px < 1 then desired_px = 1 end
    if desired_px > math.max(1, world.width - self.width + 1) then desired_px = math.max(1, world.width - self.width + 1) end

    local left_now = math.floor(self.px + 1e-6)
    local left_desired = math.floor(desired_px + 1e-6)
    local top_row = math.floor(self.py + 1e-6)
    local bottom_row = math.floor(self.py + self.height - 1e-6)
    local blocked = false

    for col = left_desired, left_now - 1 do
        if (col < 1 or col > world.width) then
            blocked = true
            desired_px = col + 1
            break
        end
        for row = top_row, bottom_row do
            if world:is_solid(self.z, col, row) then
                blocked = true
                desired_px = col + 1
                break
            end
        end
        if blocked then break end
    end

    if not blocked then
        local left_col = math.floor(desired_px + 1e-6)
        local right_col = math.floor(desired_px + self.width - 1e-6)
        for col = left_col, right_col do
            for row = top_row, bottom_row do
                if world:is_solid(self.z, col, row) then
                    desired_px = col + 1
                    blocked = true
                    break
                end
            end
            if blocked then break end
        end
    end

    if blocked then self.vx = 0 end
    self.px = desired_px
end

-- Move down helper.
local function move_down(self, desired_py, world)
    -- clamp world bounds
    if desired_py < 1 then desired_py = 1 end
    if desired_py > math.max(1, world.height - self.height + 1) then desired_py = math.max(1, world.height - self.height + 1) end

    local top_row = math.floor(self.py + 1e-6)
    local bottom_now = math.floor(self.py + self.height - 1e-6)
    local bottom_desired = math.floor(desired_py + self.height - 1e-6)
    local left_col = math.floor(self.px + 1e-6)
    local right_col = math.floor(self.px + self.width - 1e-6)
    local blocked = false

    for row = bottom_now + 1, bottom_desired do
        if (row < 1 or row > world.height) then
            blocked = true
            desired_py = row - self.height
            break
        end
        for col = left_col, right_col do
            if world:is_solid(self.z, col, row) then
                blocked = true
                desired_py = row - self.height
                break
            end
        end
        if blocked then break end
    end

    if blocked then
        self.vy = 0
        self.on_ground = true
    else
        local top_row2 = math.floor(desired_py + 1e-6)
        local bottom_row2 = math.floor(desired_py + self.height - 1e-6)
        for row = top_row2, bottom_row2 do
            for col = left_col, right_col do
                if world:is_solid(self.z, col, row) then
                    desired_py = row - self.height
                    blocked = true
                    break
                end
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
end

-- Move up helper.
local function move_up(self, desired_py, world)
    -- clamp world bounds
    if desired_py < 1 then desired_py = 1 end
    if desired_py > math.max(1, world.height - self.height + 1) then desired_py = math.max(1, world.height - self.height + 1) end

    local top_now = math.floor(self.py + 1e-6)
    local top_desired = math.floor(desired_py + 1e-6)
    local left_col = math.floor(self.px + 1e-6)
    local right_col = math.floor(self.px + self.width - 1e-6)
    local blocked = false

    for row = top_desired, top_now - 1 do
        if (row < 1 or row > world.height) then
            blocked = true
            desired_py = row + 1
            break
        end
        for col = left_col, right_col do
            if world:is_solid(self.z, col, row) then
                blocked = true
                desired_py = row + 1
                break
            end
        end
        if blocked then break end
    end

    if blocked then self.vy = 0 end
    self.py = desired_py
end

-- Public API: move(self, dx, dy, world)
-- Axis-separated: horizontal then vertical.
function Physics.move(self, dx, dy, world)
    -- horizontal
    if dx ~= 0 then
        local desired_px = self.px + dx
        if desired_px > self.px then
            move_right(self, desired_px, world)
        else
            move_left(self, desired_px, world)
        end
    end

    -- vertical
    if dy ~= 0 then
        local desired_py = self.py + dy
        if desired_py > self.py then
            move_down(self, desired_py, world)
        else
            move_up(self, desired_py, world)
        end
    end
end

return Physics