local Object = require("lib.object")
local Blocks = require("data.blocks")
local Items = require("data.items")
local Physics = require("world.physics")
local Navigation = require("entities.components.navigation")
local Gravity = require("entities.components.gravity")
local Inventory = require("entities.components.inventory")
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
    self.px = 100  -- 50 * 2 to account for terrain scaling
    self.py = 1
    self.z  = 0
    self.width = 2  -- 1 * 2 to match 2x2 subdivision
    self.height = 4  -- 2 * 2 to match 2x2 subdivision
    self.stand_height = self.height
    self.crouch_height = self.height / 2
    self.vx = 0
    self.vy = 0

    -- State system
    self.movement_state = MovementState.AIRBORNE
    self.stance = Stance.STANDING

    -- Selection size for placing/removing blocks (in world blocks)
    self.selection_size = 1  -- Can be 1, 2, or 4

    -- Inventory system: hand (held item) + belt (hotbar) + storage (3x9 grid)
    -- Using Inventory component for both
    self.inventory = {
        hand = Inventory(self, { slots = 1 }),  -- Single slot for held item
        belt = Inventory(self, { slots = 9 }),  -- 9-slot hotbar
        storage = Inventory(self, { slots = 27 }),  -- 3x9 storage grid
        ui = {
            slot_size = 48,
            padding = 6,
            border_thickness = 3,
            background_alpha = 0.6,
            open = false,  -- Whether inventory screen is open
            held_item = nil,  -- Item being dragged: { proto, count, data, source_inv, source_slot }
        },
    }

    -- Start with 64 cobblestone in first belt slot
    self.inventory.belt:add(Blocks.cobblestone, 64)
    
    -- Add some test items to storage
    self.inventory.storage:add(Blocks.dirt, 32)
    self.inventory.storage:add(Blocks.grass, 16)
    self.inventory.storage:add(Blocks.stone, 48)
    
    self.intent = { left = false, right = false, jump = false, crouch = false, run = false }

    -- Initialize components
    self.navigation = Navigation(G.world, self)
    self.gravity = Gravity(self)
end

function Player:is_grounded()
    return self.movement_state == MovementState.GROUNDED
end

function Player:is_crouching()
    return self.stance == Stance.CROUCHING
end

function Player:keypressed(key)
    if key == "tab" then
        self.inventory.ui.open = not self.inventory.ui.open
        -- Release held item when closing inventory
        if not self.inventory.ui.open and self.inventory.ui.held_item then
            self:release_held_item()
        end
    elseif key == "q" then
        self.navigation:switch_layer(-1, G.world)
    elseif key == "e" then
        self.navigation:switch_layer(1, G.world)
    elseif key == "space" or key == "up" then
        if not self.inventory.ui.open then
            self.intent.jump = true
        end
    end
end

function Player:update(dt, world, player)
    -- Ignore world and player parameters for the Player itself

    -- Don't process movement if inventory is open
    if self.inventory.ui.open then
        self.vx = 0
        self.vy = 0
        return
    end

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

    -- In DEBUG mode, enable flying with up/down controls
    if G.debug then
        local vertical_dir = 0
        if love.keyboard.isDown("space") or love.keyboard.isDown("up") or love.keyboard.isDown("w") then
            vertical_dir = vertical_dir - 1  -- Up (negative y is up)
        end
        if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
            vertical_dir = vertical_dir + 1  -- Down
        end

        local target_vy = vertical_dir * MAX_SPEED
        if vertical_dir ~= 0 then
            if self.vy < target_vy then
                self.vy = math.min(target_vy, self.vy + accel * dt)
            elseif self.vy > target_vy then
                self.vy = math.max(target_vy, self.vy - accel * dt)
            end
        else
            -- Apply friction when no vertical input
            local dec = C.AIR_FRICTION * dt
            if math.abs(self.vy) <= dec then self.vy = 0 else self.vy = self.vy - (self.vy > 0 and 1 or -1) * dec end
        end
    else
        -- Normal jump behavior when not in debug mode
        if self.intent.jump then
            if self:is_grounded() then
                self.vy = C.JUMP_SPEED
                self.movement_state = MovementState.AIRBORNE
            end
            self.intent.jump = false
        end
    end

    -- Apply gravity using component (disabled in debug mode for player)
    self.gravity:update(dt)
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
    local cx = G.camera:get_x()
    local sx = (self.px - 1) * C.BLOCK_SIZE - cx
    local sy = (self.py - 1) * C.BLOCK_SIZE
    love.graphics.setColor(T.fg[1], T.fg[2], T.fg[3], (T.fg[4] or 1))
    love.graphics.rectangle("fill", sx, sy, self.width * C.BLOCK_SIZE, self.height * C.BLOCK_SIZE)
end

function Player:wheelmoved(dx, dy)
    if not dy or dy == 0 then return end
    
    -- Don't scroll when inventory is open
    if self.inventory.ui.open then return end

    -- Check if control is held for selection size change
    local ctrl_held = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")

    if ctrl_held then
        -- Change selection size with Ctrl+scroll
        if dy > 0 then
            -- Scroll up: increase size
            if self.selection_size == 1 then
                self.selection_size = 2
            elseif self.selection_size == 2 then
                self.selection_size = 4
            end
            -- Already at max (4), stay there
        else
            -- Scroll down: decrease size
            if self.selection_size == 4 then
                self.selection_size = 2
            elseif self.selection_size == 2 then
                self.selection_size = 1
            end
            -- Already at min (1), stay there
        end
    else
        -- Normal belt selection change
        local belt = self.inventory.belt
        if dy > 0 then
            belt.selected = belt.selected - 1
            if belt.selected < 1 then belt.selected = belt.slots end
        else
            belt.selected = belt.selected + 1
            if belt.selected > belt.slots then belt.selected = 1 end
        end
    end
end

function Player:drawInventory()
    local belt = self.inventory.belt
    local ui = self.inventory.ui
    local total_width = belt.slots * ui.slot_size + (belt.slots - 1) * ui.padding
    local x0 = (G.width - total_width) / 2
    local y0 = G.height - ui.slot_size - 20
    local bg_margin = 8
    love.graphics.setColor(0,0,0,ui.background_alpha)
    love.graphics.rectangle("fill", x0 - bg_margin, y0 - bg_margin, total_width + bg_margin*2, ui.slot_size + bg_margin*2, 6, 6)
    for i = 1, belt.slots do
        local sx = x0 + (i-1)*(ui.slot_size + ui.padding)
        local sy = y0
        love.graphics.setColor(0.12,0.12,0.12,1)
        love.graphics.rectangle("fill", sx, sy, ui.slot_size, ui.slot_size, 4, 4)
        local inner_pad = 8
        local cube_x, cube_y = sx + inner_pad, sy + inner_pad
        local cube_w, cube_h = ui.slot_size - inner_pad*2, ui.slot_size - inner_pad*2
        local item = belt.items[i]
        -- Handle inventory format: { proto, count, data }
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
            love.graphics.print(tostring(count), sx + 4, sy + ui.slot_size - 16)
        end
        love.graphics.setColor(0,0,0,0.6)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", sx + 0.5, sy + 0.5, ui.slot_size - 1, ui.slot_size - 1, 4, 4)
        if i == belt.selected then
            love.graphics.setColor(1, 0.84, 0, 1)
            love.graphics.setLineWidth(ui.border_thickness)
            love.graphics.rectangle("line", sx + 1, sy + 1, ui.slot_size - 2, ui.slot_size - 2, 4, 4)
            love.graphics.setLineWidth(1)
        end
    end
    love.graphics.setColor(1,1,1,1)
end

function Player:drawGhost()
    -- Don't show ghost when inventory screen is open
    if self.inventory.ui.open then return end
    
    -- Always show ghost block, even when no item is selected
    local belt = self.inventory.belt
    local ui = self.inventory.ui
    local total_width = belt.slots * ui.slot_size + (belt.slots - 1) * ui.padding
    local x0 = (G.width - total_width) / 2
    local y0 = G.height - ui.slot_size - 20
    local bg_margin = 8
    local inv_top = y0 - bg_margin

    -- Don't show ghost if mouse is over inventory
    if G.my >= inv_top then return end

    -- Convert mouse screen position to world position
    local cx = G.camera:get_x()
    local world_px = G.mx + cx
    local col = math.floor(world_px / C.BLOCK_SIZE) + 1
    local row = math.floor(G.my / C.BLOCK_SIZE) + 1
    row = math.max(1, math.min(C.WORLD_HEIGHT, row))

    -- Calculate the top-left corner of the selection based on size
    local size = self.selection_size
    local start_col = col
    local start_row = row

    -- Center the selection around the cursor position
    if size > 1 then
        start_col = col - math.floor(size / 2)
        start_row = row - math.floor(size / 2)
    end

    -- Convert world grid position back to screen position
    local px = (start_col - 1) * C.BLOCK_SIZE - cx
    local py = (start_row - 1) * C.BLOCK_SIZE
    local width = size * C.BLOCK_SIZE
    local height = size * C.BLOCK_SIZE

    -- Draw ghost outline
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px + 0.5, py + 0.5, width - 1, height - 1)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

function Player:placeAtMouse(mx, my, z_override)
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then mouse_x, mouse_y = love.mouse.getPosition() end
    local belt = self.inventory.belt
    local selected = belt.selected or 1
    local item = belt.items and belt.items[selected]
    if not item then return false, "no item selected" end

    -- Handle inventory format: { proto, count, data }
    local proto = item.proto or item
    local count = item.count or 1

    if count <= 0 then return false, "no items left" end

    local cx = G.camera:get_x()
    local world_px = mouse_x + cx
    local col = math.floor(world_px / C.BLOCK_SIZE) + 1
    local row = math.floor(mouse_y / C.BLOCK_SIZE) + 1
    row = math.max(1, math.min(C.WORLD_HEIGHT, row))

    -- Calculate the top-left corner of the selection based on size
    local size = self.selection_size
    local start_col = col
    local start_row = row

    -- Center the selection around the cursor position
    if size > 1 then
        start_col = col - math.floor(size / 2)
        start_row = row - math.floor(size / 2)
    end

    -- Only allow editing on current layer
    local z = self.z

    -- Check if all target positions are empty
    for dx = 0, size - 1 do
        for dy = 0, size - 1 do
            local target_col = start_col + dx
            local target_row = start_row + dy
            if target_row >= 1 and target_row <= C.WORLD_HEIGHT then
                local target = G.world:get_block_type(z, target_col, target_row)
                if target ~= "air" then
                    return false, "target not empty", z
                end
            end
        end
    end

    -- Check if at least one block touches existing terrain
    local touches_existing = false
    for dx = 0, size - 1 do
        for dy = 0, size - 1 do
            local target_col = start_col + dx
            local target_row = start_row + dy
            -- Check neighbors
            for ndx = -1, 1 do
                for ndy = -1, 1 do
                    if not (ndx == 0 and ndy == 0) then
                        local nx, ny = target_col + ndx, target_row + ndy
                        if ny >= 1 and ny <= C.WORLD_HEIGHT then
                            local neigh = G.world:get_block_type(z, nx, ny)
                            if neigh and neigh ~= "air" and neigh ~= "out" then
                                -- Make sure the neighbor isn't part of our selection
                                local is_in_selection = (nx >= start_col and nx < start_col + size and
                                                        ny >= start_row and ny < start_row + size)
                                if not is_in_selection then
                                    touches_existing = true
                                    break
                                end
                            end
                        end
                    end
                end
                if touches_existing then break end
            end
            if touches_existing then break end
        end
        if touches_existing then break end
    end

    if not touches_existing then
        return false, "must touch an existing block on the same layer", z
    end

    -- Place all blocks in the selection
    local placed_count = 0
    for dx = 0, size - 1 do
        for dy = 0, size - 1 do
            local target_col = start_col + dx
            local target_row = start_row + dy
            if target_row >= 1 and target_row <= C.WORLD_HEIGHT then
                local ok, action = G.world:set_block(z, target_col, target_row, proto)
                if ok then
                    placed_count = placed_count + 1
                end
            end
        end
    end

    -- Decrement count based on blocks placed
    if placed_count > 0 and item.count then
        item.count = item.count - placed_count
        if item.count <= 0 then
            belt.items[selected] = nil
        end
    end

    return placed_count > 0, placed_count > 0 and "placed" or "failed", z
end

function Player:removeAtMouse(mx, my, z_override)
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then mouse_x, mouse_y = love.mouse.getPosition() end
    local cx = G.camera:get_x()
    local world_px = mouse_x + cx
    local col = math.floor(world_px / C.BLOCK_SIZE) + 1
    local row = math.floor(mouse_y / C.BLOCK_SIZE) + 1
    row = math.max(1, math.min(C.WORLD_HEIGHT, row))

    -- Calculate the top-left corner of the selection based on size
    local size = self.selection_size
    local start_col = col
    local start_row = row

    -- Center the selection around the cursor position
    if size > 1 then
        start_col = col - math.floor(size / 2)
        start_row = row - math.floor(size / 2)
    end

    -- Only allow editing on current layer
    local z = self.z

    -- Remove all blocks in the selection and drop each at its center
    local removed_count = 0

    for dx = 0, size - 1 do
        for dy = 0, size - 1 do
            local target_col = start_col + dx
            local target_row = start_row + dy
            if target_row >= 1 and target_row <= C.WORLD_HEIGHT then
                local t = G.world:get_block_type(z, target_col, target_row)
                if t and t ~= "air" and t ~= "out" then
                    -- Store the block type before removing it
                    local block_proto = t

                    local ok, msg = G.world:set_block(z, target_col, target_row, nil)
                    if not ok then
                       G.world:set_block(z, target_col, target_row, "__empty")
                    end

                    if ok then
                        removed_count = removed_count + 1
                        -- Drop the block at its center position using Block:drop()
                        if block_proto and block_proto ~= "air" and block_proto ~= "out" then
                            if type(block_proto.drop) == "function" then
                                block_proto:drop(G.world, target_col, target_row, z, 1)
                            end
                        end
                    end
                end
            end
        end
    end

    if removed_count > 0 then
        return true, "removed " .. removed_count, z
    end
    return false, "nothing to remove", z
end

function Player:get_inventory_slot_at(mx, my)
    -- Returns: inventory, slot_index or nil
    if not self.inventory.ui.open then
        return nil, nil
    end

    local ui = self.inventory.ui
    local slot_size = ui.slot_size
    local padding = ui.padding
    
    -- Calculate inventory screen dimensions
    local cols = 9
    local storage_rows = 3
    local grid_width = cols * slot_size + (cols - 1) * padding
    local storage_height = storage_rows * slot_size + (storage_rows - 1) * padding
    local hotbar_height = slot_size
    local total_height = storage_height + padding * 4 + hotbar_height
    
    -- Center the inventory
    local inv_x = (G.width - grid_width) / 2
    local inv_y = (G.height - total_height) / 2
    
    -- Check storage grid (3x9)
    for row = 0, storage_rows - 1 do
        for col = 0, cols - 1 do
            local sx = inv_x + col * (slot_size + padding)
            local sy = inv_y + row * (slot_size + padding)
            if mx >= sx and mx < sx + slot_size and my >= sy and my < sy + slot_size then
                local slot_idx = row * cols + col + 1
                return self.inventory.storage, slot_idx
            end
        end
    end
    
    -- Check hotbar (below storage with gap)
    local hotbar_y = inv_y + storage_height + padding * 4
    for col = 0, cols - 1 do
        local sx = inv_x + col * (slot_size + padding)
        local sy = hotbar_y
        if mx >= sx and mx < sx + slot_size and my >= sy and my < sy + slot_size then
            return self.inventory.belt, col + 1
        end
    end
    
    return nil, nil
end

function Player:inventory_click(mx, my, button)
    if not self.inventory.ui.open then
        return false
    end

    local inv, slot = self:get_inventory_slot_at(mx, my)
    if not inv then
        -- Clicked outside inventory - drop held item if any
        if self.inventory.ui.held_item then
            self:release_held_item()
        end
        return true
    end

    local ui = self.inventory.ui
    
    if button == 1 then  -- Left click
        if ui.held_item then
            -- Placing an item
            local target_item = inv.items[slot]
            if not target_item then
                -- Empty slot - place all
                inv.items[slot] = {
                    proto = ui.held_item.proto,
                    count = ui.held_item.count,
                    data = ui.held_item.data or {}
                }
                ui.held_item = nil
            elseif target_item.proto == ui.held_item.proto then
                -- Same item type - try to stack
                local max_stack = math.min(ui.held_item.proto.max_stack or C.MAX_STACK, C.MAX_STACK)
                local space = max_stack - target_item.count
                if space > 0 then
                    local to_add = math.min(space, ui.held_item.count)
                    target_item.count = target_item.count + to_add
                    ui.held_item.count = ui.held_item.count - to_add
                    if ui.held_item.count <= 0 then
                        ui.held_item = nil
                    end
                else
                    -- Swap items
                    local temp = ui.held_item
                    ui.held_item = {
                        proto = target_item.proto,
                        count = target_item.count,
                        data = target_item.data or {}
                    }
                    inv.items[slot] = temp
                end
            else
                -- Different item type - swap
                local temp = ui.held_item
                ui.held_item = {
                    proto = target_item.proto,
                    count = target_item.count,
                    data = target_item.data or {}
                }
                inv.items[slot] = temp
            end
        else
            -- Picking up an item
            local item = inv.items[slot]
            if item then
                ui.held_item = {
                    proto = item.proto,
                    count = item.count,
                    data = item.data or {},
                    source_inv = inv,
                    source_slot = slot
                }
                inv.items[slot] = nil
            end
        end
    elseif button == 2 then  -- Right click
        if ui.held_item then
            -- Place single item
            local target_item = inv.items[slot]
            if not target_item then
                -- Empty slot - place one
                inv.items[slot] = {
                    proto = ui.held_item.proto,
                    count = 1,
                    data = {}
                }
                ui.held_item.count = ui.held_item.count - 1
                if ui.held_item.count <= 0 then
                    ui.held_item = nil
                end
            elseif target_item.proto == ui.held_item.proto then
                -- Same item type - add one if space
                local max_stack = math.min(ui.held_item.proto.max_stack or C.MAX_STACK, C.MAX_STACK)
                if target_item.count < max_stack then
                    target_item.count = target_item.count + 1
                    ui.held_item.count = ui.held_item.count - 1
                    if ui.held_item.count <= 0 then
                        ui.held_item = nil
                    end
                end
            end
        else
            -- Pick up half
            local item = inv.items[slot]
            if item then
                local pick_count = math.ceil(item.count / 2)
                ui.held_item = {
                    proto = item.proto,
                    count = pick_count,
                    data = {},
                    source_inv = inv,
                    source_slot = slot
                }
                item.count = item.count - pick_count
                if item.count <= 0 then
                    inv.items[slot] = nil
                end
            end
        end
    end
    
    return true
end

function Player:release_held_item()
    -- Drop held item back to world or put it back
    local ui = self.inventory.ui
    if not ui.held_item then return end
    
    -- Try to add to storage first
    local leftover = self.inventory.storage:add(ui.held_item.proto, ui.held_item.count)
    if leftover > 0 then
        -- Try to add to belt
        leftover = self.inventory.belt:add(ui.held_item.proto, leftover)
    end
    
    -- If still leftover, drop to world
    if leftover > 0 then
        local drop_x = self.px + self.width / 2
        local drop_y = self.py + self.height / 2
        if ui.held_item.proto and type(ui.held_item.proto.drop) == "function" then
            ui.held_item.proto:drop(G.world, drop_x, drop_y, self.z, leftover)
        end
    end
    
    ui.held_item = nil
end

function Player:drawInventoryScreen()
    if not self.inventory.ui.open then
        return
    end

    local ui = self.inventory.ui
    local slot_size = ui.slot_size
    local padding = ui.padding
    local border = ui.border_thickness
    
    -- Inventory dimensions
    local cols = 9
    local storage_rows = 3
    local grid_width = cols * slot_size + (cols - 1) * padding
    local storage_height = storage_rows * slot_size + (storage_rows - 1) * padding
    local hotbar_height = slot_size
    local total_height = storage_height + padding * 4 + hotbar_height
    
    -- Center the inventory
    local inv_x = (G.width - grid_width) / 2
    local inv_y = (G.height - total_height) / 2
    
    -- Semi-transparent background
    local bg_margin = 20
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 
        inv_x - bg_margin, 
        inv_y - bg_margin, 
        grid_width + bg_margin * 2, 
        total_height + bg_margin * 2, 
        8, 8)
    
    -- Draw storage grid (3x9)
    for row = 0, storage_rows - 1 do
        for col = 0, cols - 1 do
            local sx = inv_x + col * (slot_size + padding)
            local sy = inv_y + row * (slot_size + padding)
            local slot_idx = row * cols + col + 1
            self:drawInventorySlot(sx, sy, slot_size, self.inventory.storage, slot_idx, false)
        end
    end
    
    -- Draw hotbar (below storage with gap)
    local hotbar_y = inv_y + storage_height + padding * 4
    for col = 0, cols - 1 do
        local sx = inv_x + col * (slot_size + padding)
        local sy = hotbar_y
        local slot_idx = col + 1
        local is_selected = (slot_idx == self.inventory.belt.selected)
        self:drawInventorySlot(sx, sy, slot_size, self.inventory.belt, slot_idx, is_selected)
    end
    
    -- Draw held item at mouse cursor
    if ui.held_item then
        local mx, my = love.mouse.getPosition()
        local item_size = 32
        local ix = mx - item_size / 2
        local iy = my - item_size / 2
        
        local proto = ui.held_item.proto
        if proto and proto.color then
            local r, g, b, a = unpack(proto.color)
            if r and r > 1 then
                r, g, b, a = r/255, (g or 0)/255, (b or 0)/255, (a or 255)/255
            end
            love.graphics.setColor(r or 1, g or 1, b or 1, (a or 1) * 0.8)
            love.graphics.rectangle("fill", ix, iy, item_size, item_size, 3, 3)
        end
        
        -- Draw count
        if ui.held_item.count > 1 then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(tostring(ui.held_item.count), ix + 4, iy + item_size - 16)
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

function Player:drawInventorySlot(x, y, size, inventory, slot_idx, is_selected)
    local ui = self.inventory.ui
    
    -- Slot background
    love.graphics.setColor(0.12, 0.12, 0.12, 1)
    love.graphics.rectangle("fill", x, y, size, size, 4, 4)
    
    -- Item in slot
    local item = inventory.items[slot_idx]
    if item then
        local proto = item.proto or item
        local count = item.count
        
        local inner_pad = 8
        local cube_x, cube_y = x + inner_pad, y + inner_pad
        local cube_w, cube_h = size - inner_pad * 2, size - inner_pad * 2
        
        if proto and proto.color then
            local r, g, b, a = unpack(proto.color)
            if r and r > 1 then
                r, g, b, a = r/255, (g or 0)/255, (b or 0)/255, (a or 255)/255
            end
            love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
            love.graphics.rectangle("fill", cube_x, cube_y, cube_w, cube_h, 3, 3)
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.rectangle("line", cube_x + 0.5, cube_y + 0.5, cube_w - 1, cube_h - 1, 2, 2)
        end
        
        -- Draw count
        if count and count > 1 then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(tostring(count), x + 4, y + size - 16)
        end
    end
    
    -- Slot border
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, size - 1, size - 1, 4, 4)
    
    -- Highlight selected slot
    if is_selected then
        love.graphics.setColor(1, 0.84, 0, 1)
        love.graphics.setLineWidth(ui.border_thickness)
        love.graphics.rectangle("line", x + 1, y + 1, size - 2, size - 2, 4, 4)
        love.graphics.setLineWidth(1)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
end

return Player
