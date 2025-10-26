-- Player module (includes inventory UI + wheel handling + held-block ghost + placement/removal)
-- Movement/collision updated so player cannot overlap blocks (hard stop).
-- Horizontal and vertical movement now resolve AABB collisions against world:get_block_type.
--
-- Notes:
--  - Coordinates are in block units (px, py are continuous; blocks are integer grid 1..N).
--  - Player occupies columns floor(px) .. floor(px + width - eps) and rows floor(py) .. floor(py + height - eps).
--  - Movement is resolved in two phases each frame: horizontal then vertical.
--  - When a collision is detected the player is moved to be flush against the blocking tile and velocity along that axis is zeroed.
--
local Player = {}
Player.__index = Player

local Blocks = require("blocks") -- used to seed inventory with block types

-- Helper: safe getters for world dimensions (tries numeric field, then method, then Game fallback)
local function safe_world_dims(world)
    local w, h = nil, nil
    if world then
        if type(world.width) == "number" then w = world.width end
        if type(world.height) == "number" then h = world.height end
        -- try methods if fields not present
        if not w then
            local ok, val = pcall(function() return world:width() end)
            if ok and type(val) == "number" then w = val end
        end
        if not h then
            local ok, val = pcall(function() return world:height() end)
            if ok and type(val) == "number" then h = val end
        end
    end
    if not w and rawget(_G, "Game") and Game.WORLD_WIDTH then w = Game.WORLD_WIDTH end
    if not h and rawget(_G, "Game") and Game.WORLD_HEIGHT then h = Game.WORLD_HEIGHT end
    return w, h
end

-- small epsilon to avoid floating rounding issues when mapping to integer block indices
local EPS = 1e-6

-- check whether a tile at (z, col, row) is solid (non-air and not out-of-bounds)
local function tile_solid(world, z, col, row)
    if not world then return false end
    local t = world:get_block_type(z, col, row)
    if not t then return false end
    return (t ~= "air" and t ~= "out")
end

-- Create a new player. opts may include px, py, z
function Player.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Player)
    self.px = opts.px or 50       -- column (blocks) (continuous)
    self.py = opts.py or 0        -- row (blocks) (continuous)
    self.z  = opts.z  or 0        -- layer
    self.vx = 0
    self.vy = 0
    self.width = opts.width or 1  -- block width
    self.height = opts.height or 2 -- block height
    self.on_ground = false

    -- Inventory (owned by player)
    local slots = 9
    self.inventory = {
        slots = slots,
        selected = 1,
        items = {}, -- will be populated below
        ui = {
            slot_size = 48,         -- pixel size of each inventory slot
            padding = 6,            -- padding between slots
            border_thickness = 3,
            background_alpha = 0.6,
        }
    }

    -- Seed inventory with one of each block from Blocks (stop when bar is full).
    for name, block in pairs(Blocks) do
        if #self.inventory.items >= self.inventory.slots then break end
        table.insert(self.inventory.items, block)
    end

    return self
end

-- Basic update (keeps previous behavior compatible; world used for ground detection)
-- This update resolves collisions so player cannot enter solid tiles.
-- input = { left = bool, right = bool, jump = bool }
function Player:update(dt, world, input)
    -- Basic horizontal movement (use Game constants if available)
    local move_speed = (rawget(_G, "Game") and Game.MOVE_SPEED) or 5
    if input and input.left then
        self.vx = -move_speed
    elseif input and input.right then
        self.vx = move_speed
    else
        self.vx = 0
    end

    -- Gravity and vertical movement
    local gravity = (rawget(_G, "Game") and Game.GRAVITY) or 20
    self.vy = self.vy + gravity * dt

    -- Integrate and resolve collisions in two steps:
    -- 1) Horizontal move + horizontal collision resolution (dead stop)
    -- 2) Vertical move + vertical collision resolution (landing, ceiling hit)

    local world_w, world_h = safe_world_dims(world)
    -- keep local copies for convenience
    local z = self.z

    -- current integer span helper
    local function horiz_span_px(px)
        -- columns the player overlaps given left px
        local left_col = math.floor(px + EPS)
        local right_col = math.floor(px + self.width - EPS)
        return left_col, right_col
    end
    local function vert_span_py(py)
        local top_row = math.floor(py + EPS)
        local bottom_row = math.floor(py + self.height - EPS)
        return top_row, bottom_row
    end

    -- HORIZONTAL
    local desired_px = self.px + self.vx * dt
    -- clamp horizontally to world bounds (leftmost is 1, rightmost is world_w - width + small)
    if world_w then
        local min_px = 1
        local max_px = math.max(1, world_w - self.width + 1) -- allow px so that floor(px + width - eps) <= world_w
        if desired_px < min_px then desired_px = min_px end
        if desired_px > max_px then desired_px = max_px end
    end

    if math.abs(desired_px - self.px) > EPS then
        if desired_px > self.px then
            -- moving right
            local _, right_now = horiz_span_px(self.px)
            local _, right_desired = horiz_span_px(desired_px)
            local top_row, bottom_row = vert_span_py(self.py)
            local blocked = false
            -- check each column we would newly touch (right_now+1 .. right_desired)
            for col = right_now + 1, right_desired do
                if world_w and (col < 1 or col > world_w) then
                    -- out of bounds considered solid
                    blocked = true
                    -- align to left of this column
                    desired_px = col - self.width
                    break
                end
                for row = top_row, bottom_row do
                    if tile_solid(world, z, col, row) then
                        blocked = true
                        -- align player's right to left edge of blocking col:
                        desired_px = col - self.width
                        break
                    end
                end
                if blocked then break end
            end
            if not blocked then
                -- Additionally, ensure we didn't end up partially inside a tile due to large step:
                -- if any overlapping column at desired_px is solid, clamp to nearest safe px
                local left_col, right_col = horiz_span_px(desired_px)
                for col = left_col, right_col do
                    for row = top_row, bottom_row do
                        if tile_solid(world, z, col, row) then
                            -- move to left of this column
                            desired_px = col - self.width
                            blocked = true
                            break
                        end
                    end
                    if blocked then break end
                end
            end
            if blocked then
                self.vx = 0
            end
            self.px = desired_px
        else
            -- moving left
            local left_now = math.floor(self.px + EPS)
            local left_desired = math.floor(desired_px + EPS)
            local top_row, bottom_row = vert_span_py(self.py)
            local blocked = false
            -- check each column we'd newly touch on the left (left_desired .. left_now -1)
            for col = left_desired, left_now - 1 do
                if world_w and (col < 1 or col > world_w) then
                    blocked = true
                    -- align to right edge of this column: px = col + 1
                    desired_px = col + 1
                    break
                end
                for row = top_row, bottom_row do
                    if tile_solid(world, z, col, row) then
                        blocked = true
                        -- align player's left to right edge of blocking col
                        desired_px = col + 1
                        break
                    end
                end
                if blocked then break end
            end
            if not blocked then
                -- sanity check overlapping columns at desired_px
                local left_col, right_col = horiz_span_px(desired_px)
                for col = left_col, right_col do
                    for row = top_row, bottom_row do
                        if tile_solid(world, z, col, row) then
                            desired_px = col + 1
                            blocked = true
                            break
                        end
                    end
                    if blocked then break end
                end
            end
            if blocked then
                self.vx = 0
            end
            self.px = desired_px
        end
    end

    -- VERTICAL
    local desired_py = self.py + self.vy * dt
    -- clamp vertical to world bounds if possible
    if world_h then
        local min_py = 1
        local max_py = math.max(1, world_h - self.height + 1)
        if desired_py < min_py then desired_py = min_py end
        if desired_py > max_py then desired_py = max_py end
    end

    if math.abs(desired_py - self.py) > EPS then
        if desired_py > self.py then
            -- moving down
            local top_row, bottom_now = vert_span_py(self.py)
            local _, bottom_desired = vert_span_py(desired_py)
            local left_col, right_col = horiz_span_px(self.px)
            local blocked = false
            for row = bottom_now + 1, bottom_desired do
                if world_h and (row < 1 or row > world_h) then
                    blocked = true
                    desired_py = row - self.height
                    break
                end
                for col = left_col, right_col do
                    if tile_solid(world, z, col, row) then
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
                -- sanity: if overlapping after move, snap up
                local top_row2, bottom_row2 = vert_span_py(desired_py)
                for row = top_row2, bottom_row2 do
                    for col = left_col, right_col do
                        if tile_solid(world, z, col, row) then
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
        else
            -- moving up
            local top_now = math.floor(self.py + EPS)
            local top_desired = math.floor(desired_py + EPS)
            local left_col, right_col = horiz_span_px(self.px)
            local blocked = false
            for row = top_desired, top_now - 1 do
                if world_h and (row < 1 or row > world_h) then
                    blocked = true
                    desired_py = row + 1
                    break
                end
                for col = left_col, right_col do
                    if tile_solid(world, z, col, row) then
                        blocked = true
                        desired_py = row + 1
                        break
                    end
                end
                if blocked then break end
            end
            if blocked then
                self.vy = 0
            end
            self.py = desired_py
            -- left on_ground unchanged when hitting ceiling
        end
    end

    -- clamp inside world width if possible (ensure px within reasonable bounds)
    if rawget(_G, "Game") then
        local max_x = Game.WORLD_WIDTH - self.width + 1
        if self.px < 1 then self.px = 1 end
        if self.px > max_x then self.px = max_x end
    end
end

-- Draw player as a simple rectangle (block-space -> pixel-space)
-- block_size: pixels per block, camera_x: pixels
function Player:draw(block_size, camera_x)
    block_size = block_size or 16
    camera_x = camera_x or 0

    local px = (self.px - 1) * block_size - camera_x
    local py = (self.py - 1) * block_size

    -- simple body
    love.graphics.push()
    love.graphics.setColor(0.2, 0.6, 1, 1)
    love.graphics.rectangle("fill", px, py, self.width * block_size, self.height * block_size, 4, 4)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("line", px + 0.5, py + 0.5, self.width * block_size - 1, self.height * block_size - 1, 4, 4)
    love.graphics.pop()
end

-- Mouse wheel handler: forward wheel movement (y) to change selected slot
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

-- Draw the inventory selection bar centered at the bottom of the screen.
function Player:drawInventory(screen_w, screen_h)
    local inv = self.inventory
    local ui = inv.ui
    local total_slots = inv.slots
    local slot_w = ui.slot_size
    local slot_h = ui.slot_size
    local padding = ui.padding
    local total_width = total_slots * slot_w + (total_slots - 1) * padding
    local x0 = (screen_w - total_width) / 2
    local y0 = screen_h - slot_h - 20 -- 20px margin from bottom

    -- Background bar (semi-transparent dark rectangle)
    local bg_margin = 8
    love.graphics.setColor(0, 0, 0, ui.background_alpha)
    love.graphics.rectangle("fill", x0 - bg_margin, y0 - bg_margin, total_width + bg_margin * 2, slot_h + bg_margin * 2, 6, 6)

    -- Draw each slot
    for i = 1, total_slots do
        local sx = x0 + (i - 1) * (slot_w + padding)
        local sy = y0

        -- slot background
        love.graphics.setColor(0.12, 0.12, 0.12, 1)
        love.graphics.rectangle("fill", sx, sy, slot_w, slot_h, 4, 4)

        -- inner "cube" placeholder or item color
        local inner_pad = 8
        local cube_x = sx + inner_pad
        local cube_y = sy + inner_pad
        local cube_w = slot_w - inner_pad * 2
        local cube_h = slot_h - inner_pad * 2

        local item = inv.items[i]
        if item and item.color then
            love.graphics.setColor(unpack(item.color))
            love.graphics.rectangle("fill", cube_x, cube_y, cube_w, cube_h, 3, 3)
            -- darker inner outline
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.rectangle("line", cube_x + 0.5, cube_y + 0.5, cube_w - 1, cube_h - 1, 2, 2)
        else
            love.graphics.setColor(0.75, 0.75, 0.75, 1)
            love.graphics.rectangle("fill", cube_x, cube_y, cube_w, cube_h, 3, 3)
        end

        -- slot border (thin)
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", sx + 0.5, sy + 0.5, slot_w - 1, slot_h - 1, 4, 4)

        -- highlight selected slot with thicker colored border
        if i == inv.selected then
            love.graphics.setColor(1, 0.84, 0, 1) -- gold-ish
            love.graphics.setLineWidth(ui.border_thickness)
            love.graphics.rectangle("line", sx + 1, sy + 1, slot_w - 2, slot_h - 2, 4, 4)
            love.graphics.setLineWidth(1)
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw the inventory ghost block (snapped grid preview)
function Player:drawGhost(world, camera_x, block_size)
    camera_x = camera_x or 0
    block_size = block_size or 16

    local inv = self.inventory
    local selected = inv.selected or 1
    local item = inv.items and inv.items[selected]

    if not item or not item.color then return end

    -- compute inventory UI region to avoid drawing ghost on top of the bar
    local screen_w = love.graphics.getWidth()
    local screen_h = love.graphics.getHeight()
    local ui = inv.ui
    local total_slots = inv.slots
    local slot_w = ui.slot_size
    local slot_h = ui.slot_size
    local padding = ui.padding
    local total_width = total_slots * slot_w + (total_slots - 1) * padding
    local x0 = (screen_w - total_width) / 2
    local y0 = screen_h - slot_h - 20 -- 20px margin from bottom
    local bg_margin = 8
    local inv_top = y0 - bg_margin

    local mx, my = love.mouse.getPosition()
    if my >= inv_top then return end

    local world_px = mx + camera_x
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(my / block_size) + 1

    local world_w, world_h = safe_world_dims(world)
    if world_w then col = math.max(1, math.min(world_w, col)) end
    if world_h then row = math.max(1, math.min(world_h, row)) end

    local px = (col - 1) * block_size - camera_x
    local py = (row - 1) * block_size

    local r, g, b, a = unpack(item.color)
    a = (a or 1) * 0.45 -- semi-transparent
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", px, py, block_size, block_size)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", px + 0.5, py + 0.5, block_size - 1, block_size - 1)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Place the selected hotbar block at the mouse world cell (right-click).
-- Floating placements are allowed (no support/sanity check for below).
-- Uses World:set_block to ensure logging occurs.
function Player:placeAtMouse(world, camera_x, block_size, mx, my)
    if not world then return false, "no world" end
    camera_x = camera_x or 0
    block_size = block_size or 16
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then
        mouse_x, mouse_y = love.mouse.getPosition()
    end

    local inv = self.inventory
    local selected = inv.selected or 1
    local item = inv.items and inv.items[selected]
    if not item then return false, "no item selected" end

    -- Determine world cell under mouse
    local world_px = mouse_x + camera_x
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(mouse_y / block_size) + 1

    -- safe world dimensions
    local world_w, world_h = safe_world_dims(world)
    if not world_w or not world_h then
        if rawget(_G, "Game") and Game.debug then
            print("Place debug: world dims unknown; world_w,world_h =", tostring(world_w), tostring(world_h))
        end
        return false, "world dimensions unknown"
    end

    -- clamp
    col = math.max(1, math.min(world_w, col))
    row = math.max(1, math.min(world_h, row))

    -- Query target
    local target_type = world:get_block_type(self.z, col, row)
    if target_type == nil then target_type = "nil" end

    -- Only place into air (air includes procedural cells that were marked "__empty")
    if target_type ~= "air" then
        return false, "target not empty"
    end

    -- find block name from the item stored in inventory
    local blockName = nil
    for k, v in pairs(Blocks) do
        if v == item then
            blockName = k
            break
        end
    end
    if not blockName then
        blockName = item.name
    end
    if not blockName then
        return false, "unknown block type"
    end

    -- Use World:set_block to add placed block (this will log)
    local ok, action = world:set_block(self.z, col, row, blockName)
    return ok, action
end

-- Remove the block at the mouse world cell (left-click). This modifies the world:
-- - if a player-placed block exists at target, remove that overlay entry
-- - otherwise, mark the procedural tile as removed by writing sentinel "__empty" into the overlay
-- The change affects world:get_block_type and get_surface immediately, and logging is done in World:set_block.
function Player:removeAtMouse(world, camera_x, block_size, mx, my)
    if not world then return false, "no world" end
    camera_x = camera_x or 0
    block_size = block_size or 16
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then
        mouse_x, mouse_y = love.mouse.getPosition()
    end

    -- Determine world cell under mouse
    local world_px = mouse_x + camera_x
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(mouse_y / block_size) + 1

    -- safe world dimensions
    local world_w, world_h = safe_world_dims(world)
    if not world_w or not world_h then
        return false, "world dimensions unknown"
    end

    -- clamp
    col = math.max(1, math.min(world_w, col))
    row = math.max(1, math.min(world_h, row))

    -- First try removing a placed block (set to nil removes placed overlay)
    local ok, msg = world:set_block(self.z, col, row, nil)
    if ok then
        return true, msg
    end

    -- If nothing removed, try marking procedural removed (use "__empty" sentinel)
    local ok2, msg2 = world:set_block(self.z, col, row, "__empty")
    if ok2 then
        return true, msg2
    end

    return false, "nothing to remove"
end

return Player