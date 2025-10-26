-- Player module (includes inventory UI + wheel handling)
-- Usage:
--   local Player = require("player")
--   local p = Player.new{ px = 50, z = 0 }
--   p:update(dt, world, input)
--   p:draw(block_size, camera_x)
--   p:wheelmoved(dx, dy)
--   p:drawInventory(screen_w, screen_h)
--
local Player = {}
Player.__index = Player

local Blocks = require("blocks") -- used to seed inventory with block types

-- Create a new player. opts may include px, py, z
function Player.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Player)
    self.px = opts.px or 50       -- column (blocks)
    self.py = opts.py or 0        -- row (blocks)
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
    -- This will not overflow if more block types are added later.
    for name, block in pairs(Blocks) do
        if #self.inventory.items >= self.inventory.slots then break end
        table.insert(self.inventory.items, block)
    end

    -- NOTE: Do NOT attempt to append `nil` values to force the array length.
    -- In Lua `#table` ignores trailing nils and appending `nil` with table.insert
    -- will not increase the length, which leads to an infinite loop. We purposely
    -- leave `inventory.items` possibly shorter than `inventory.slots` and handle
    -- missing entries as empty slots in drawInventory (inv.items[i] can be nil).

    return self
end

-- Basic update (keeps previous behavior compatible; world used for ground detection)
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

    -- Simple position integration (units are blocks)
    self.px = self.px + self.vx * dt
    self.py = self.py + self.vy * dt

    -- Clamp inside world width if possible
    if rawget(_G, "Game") then
        local max_x = Game.WORLD_WIDTH - self.width
        if self.px < 1 then self.px = 1 end
        if self.px > max_x then self.px = max_x end
    end

    -- Simple ground collision: snap to top if below surface
    if world then
        local col = math.floor(self.px)
        local top = world:get_surface(self.z, col) or ( (rawget(_G, "Game") and Game.WORLD_HEIGHT) or 100 )
        -- top is block-row of top block; player stands on top - player.height
        local ground_py = top - self.height
        if self.py >= ground_py then
            self.py = ground_py
            self.vy = 0
            self.on_ground = true
        else
            self.on_ground = false
        end
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
-- follows the previous behaviour: wheel up => previous slot, wheel down => next slot
-- dx, dy: numbers passed by love.wheelmoved
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
-- screen_w, screen_h: in pixels
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

return Player