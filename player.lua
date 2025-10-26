-- Player module (includes inventory UI + wheel handling + held-block ghost + placement/removal)
-- Left click removes the highlighted block from the world (procedural or placed).
-- Right click places the selected hotbar block (floating placement allowed).
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
    for name, block in pairs(Blocks) do
        if #self.inventory.items >= self.inventory.slots then break end
        table.insert(self.inventory.items, block)
    end

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

    -- Diagnostics when placement fails (only print when Game.debug)
    local function diag(msg)
        if rawget(_G, "Game") and Game.debug then
            local placed_val = nil
            if world.placed and world.placed[self.z] and world.placed[self.z][col] then
                placed_val = world.placed[self.z][col][row]
            end
            print(string.format("Place debug: %s | z=%d col=%d row=%d target_type=%s placed_overlay=%s",
                    msg, self.z, col, row, tostring(target_type), tostring(placed_val)))
            local layer = world.layers and world.layers[self.z]
            if layer and layer.heights then
                local h = layer.heights[col]
                local dirt = layer.dirt_limit and layer.dirt_limit[col]
                local stone = layer.stone_limit and layer.stone_limit[col]
                print(string.format("  layer heights: top=%s dirt_lim=%s stone_lim=%s", tostring(h), tostring(dirt), tostring(stone)))
            end
        end
    end

    -- Only place into air (air includes procedural cells that were marked "__empty")
    if target_type ~= "air" then
        diag("target not empty")
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
        diag("unknown block type")
        return false, "unknown block type"
    end

    local ok, err = world:place_block(self.z, col, row, blockName)
    if not ok then
        diag("place_block failed: "..tostring(err))
    end
    return ok, err
end

-- Remove the block at the mouse world cell (left-click). This modifies the world:
-- - if a player-placed block exists at target, remove that overlay entry
-- - otherwise, mark the procedural tile as removed by writing sentinel "__empty" into placed overlay
-- The change affects world:get_block_type and get_surface immediately.
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

    -- check placed overlay
    if not world.placed then world.placed = {} end
    if not world.placed[self.z] then world.placed[self.z] = {} end
    if not world.placed[self.z][col] then world.placed[self.z][col] = {} end

    local placed_val = world.placed[self.z][col][row]
    if placed_val ~= nil and placed_val ~= "__empty" then
        -- remove player-placed block
        world.placed[self.z][col][row] = nil
        if rawget(_G, "Game") and Game.debug then
            print(string.format("Remove debug: removed placed block at z=%d col=%d row=%d", self.z, col, row))
        end
        return true, "removed placed"
    end

    -- no placed block found — check procedural block
    local cur = world:get_block_type(self.z, col, row)
    if cur == nil then cur = "nil" end
    if cur == "air" or cur == "out" then
        return false, "nothing to remove"
    end

    -- mark procedural tile removed via sentinel so get_block_type will treat as air
    world.placed[self.z][col][row] = "__empty"
    if rawget(_G, "Game") and Game.debug then
        print(string.format("Remove debug: marked procedural block removed at z=%d col=%d row=%d (was %s)", self.z, col, row, tostring(cur)))
    end
    return true, "removed procedural"
end

return Player