-- Player System
-- Manages player entity and player-specific logic

require "lib"
local log = require "lib.log"

local Systems = require "systems"
local Position = require "components.position"
local Velocity = require "components.velocity"
local Physics = require "components.physics"
local Collider = require "components.collider"
local Visual = require "components.visual"
local Layer = require "components.layer"
local Inventory = require "components.inventory"
local Omnitool = require "components.omnitool"
local Stance = require "components.stance"
local Registry = require "registries"

local BLOCKS = Registry.blocks()

local PlayerSystem = {
    id = "player",
    priority = 20,
    components = {},
    -- Movement constants
    MOVE_SPEED = 150,
    JUMP_FORCE = 300,
    -- Height constants
    STANDING_HEIGHT = nil,  -- Will be set in load
    CROUCHING_HEIGHT = nil, -- Will be set in load
}

function PlayerSystem.load(self, x, y, layer)
    local world = Systems.get("world")

    -- Set height constants
    self.STANDING_HEIGHT = world.BLOCK_SIZE * 2
    self.CROUCHING_HEIGHT = self.STANDING_HEIGHT / 2

    -- Initialize player components
    self.components.position = Position.new(x, y, layer)
    self.components.velocity = Velocity.new(0, 0)
    self.components.physics = Physics.new(800, 0.95)
    self.components.collider = Collider.new(world.BLOCK_SIZE, self.STANDING_HEIGHT)
    self.components.visual = Visual.new({1, 1, 1, 1}, world.BLOCK_SIZE, self.STANDING_HEIGHT)
    self.components.layer = Layer.new(layer)
    self.components.inventory = Inventory.new(9, 64)
    self.components.omnitool = Omnitool.new(0)
    self.components.stance = Stance.new(Stance.STANDING)

    -- Initialize inventory slots
    for i = 1, self.components.inventory.hotbar_size do
        self.components.inventory.slots[i] = nil
    end

    -- Add starting items
    self:add_to_inventory(BLOCKS.DIRT, 64)
    self:add_to_inventory(BLOCKS.STONE, 32)
    self:add_to_inventory(BLOCKS.WOOD, 16)

    log.info("Player:", self.components.position:tostring())
end

function PlayerSystem.update(self, dt)
    local world = Systems.get("world")

    local pos = self.components.position
    local vel = self.components.velocity
    local phys = self.components.physics
    local col = self.components.collider
    local stance = self.components.stance
    local vis = self.components.visual

    -- Handle crouching state
    local is_crouching = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    local prev_stance = stance.current

    if is_crouching then
        stance.current = Stance.CROUCHING
    else
        -- Check if player can stand up (need clearance above)
        if prev_stance == Stance.CROUCHING then
            local can_stand = true
            local standing_top = pos.y - self.STANDING_HEIGHT / 2
            local top_row = math.floor(standing_top / world.BLOCK_SIZE)
            local left_col = math.floor((pos.x - col.width / 2) / world.BLOCK_SIZE)
            local right_col = math.floor((pos.x + col.width / 2 - EPSILON) / world.BLOCK_SIZE)

            -- Check if there's space to stand up
            for c = left_col, right_col do
                local block_def = world:get_block_def(pos.z, c, top_row)
                if block_def and block_def.solid then
                    can_stand = false
                    break
                end
            end

            if can_stand then
                stance.current = Stance.STANDING
            else
                -- Stay crouched, not enough space
                stance.current = Stance.CROUCHING
            end
        else
            stance.current = Stance.STANDING
        end
    end

    -- Adjust player position when changing stance to keep bottom at same level
    if prev_stance ~= stance.current then
        local prev_height = prev_stance == Stance.STANDING and self.STANDING_HEIGHT or self.CROUCHING_HEIGHT
        local new_height = stance.current == Stance.STANDING and self.STANDING_HEIGHT or self.CROUCHING_HEIGHT

        -- Keep the bottom of the player at the same position
        -- pos.y is center, so bottom is at pos.y + height/2
        local bottom_y = pos.y + prev_height / 2
        pos.y = bottom_y - new_height / 2
    end

    -- Update collider and visual heights
    if stance.current == Stance.CROUCHING then
        col.height = self.CROUCHING_HEIGHT
        vis.height = self.CROUCHING_HEIGHT
    else
        col.height = self.STANDING_HEIGHT
        vis.height = self.STANDING_HEIGHT
    end

    -- Calculate movement speed based on stance
    local move_speed = self.MOVE_SPEED
    if stance.current == Stance.CROUCHING then
        move_speed = move_speed * 0.5
    end

    -- Horizontal movement
    vel.vx = 0
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        vel.vx = -move_speed
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        vel.vx = move_speed
    end

    -- Vertical movement (gravity)
    vel.vy = vel.vy + phys.gravity * dt

    -- Apply horizontal velocity with collision
    local new_x = pos.x + vel.vx * dt
    local hit_wall = false

    if vel.vx ~= 0 then
        local check_col
        if vel.vx > 0 then
            check_col = math.floor((new_x + col.width / 2) / world.BLOCK_SIZE)
        else
            check_col = math.floor((new_x - col.width / 2) / world.BLOCK_SIZE)
        end

        local top_row = math.floor((pos.y - col.height / 2) / world.BLOCK_SIZE)
        local bottom_row = math.floor((pos.y + col.height / 2 - EPSILON) / world.BLOCK_SIZE)

        for row = top_row, bottom_row do
            local block_def = world:get_block_def(pos.z, check_col, row)
            if block_def and block_def.solid then
                hit_wall = true
                if vel.vx > 0 then
                    pos.x = check_col * world.BLOCK_SIZE - col.width / 2
                else
                    pos.x = (check_col + 1) * world.BLOCK_SIZE + col.width / 2
                end
                break
            end
        end

        -- Edge detection: prevent falling off edges while crouching
        local on_ground = Stance.is_on_ground(stance)
        if not hit_wall and stance.current == Stance.CROUCHING and on_ground and vel.vx ~= 0 then
            -- Check if there's ground in the next column ahead (one block over from current position)
            local next_col
            if vel.vx > 0 then
                -- Moving right: check the column to the right
                next_col = math.floor((pos.x + col.width / 2) / world.BLOCK_SIZE) + 1
            else
                -- Moving left: check the column to the left
                next_col = math.floor((pos.x - col.width / 2) / world.BLOCK_SIZE) - 1
            end

            -- Check ground one row below player's feet
            local ground_check_row = math.floor((pos.y + col.height / 2) / world.BLOCK_SIZE) + 1
            local block_def = world:get_block_def(pos.z, next_col, ground_check_row)

            -- If no ground in the next column, stop movement to prevent falling
            if not (block_def and block_def.solid) then
                hit_wall = true
            end
        end
    end

    if not hit_wall then
        pos.x = new_x
    end

    -- Apply vertical velocity with collision
    local new_y = pos.y + vel.vy * dt

    -- Ground collision
    local hit_ground = false
    local bottom_y = new_y + col.height / 2
    local left_col = math.floor((pos.x - col.width / 2) / world.BLOCK_SIZE)
    local right_col = math.floor((pos.x + col.width / 2 - EPSILON) / world.BLOCK_SIZE)
    local bottom_row = math.floor(bottom_y / world.BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, bottom_row)
        if block_def and block_def.solid and vel.vy >= 0 then
            pos.y = bottom_row * world.BLOCK_SIZE - col.height / 2
            vel.vy = 0
            hit_ground = true
            new_y = pos.y
            break
        end
    end

    -- Ceiling collision
    local top_y = new_y - col.height / 2
    local top_row = math.floor(top_y / world.BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, top_row)
        if block_def and block_def.solid and vel.vy < 0 then
            pos.y = (top_row + 1) * world.BLOCK_SIZE + col.height / 2
            vel.vy = 0
            new_y = pos.y
            break
        end
    end

    if not hit_ground then
        pos.y = new_y
        -- If not jumping, set to falling (walked off edge)
        if stance.current ~= Stance.JUMPING then
            stance.current = Stance.FALLING
        end
    end

    -- Update stance based on ground contact  
    -- When landing while jumping or falling, return to standing or crouching
    if hit_ground and (stance.current == Stance.JUMPING or stance.current == Stance.FALLING) then
        -- Land on ground - return to standing or crouching based on input
        local is_crouching = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
        if is_crouching then
            stance.current = Stance.CROUCHING
        else
            stance.current = Stance.STANDING
        end
    end

    -- Jump (after ground detection so we know if we're on ground)
    -- Can only jump if on ground (not jumping or falling)
    if (love.keyboard.isDown("w") or love.keyboard.isDown("space") or love.keyboard.isDown("up")) and hit_ground and (stance.current == Stance.STANDING or stance.current == Stance.CROUCHING) then
        -- Jump height is half when crouching
        local jump_force = self.JUMP_FORCE
        if stance.current == Stance.CROUCHING then
            jump_force = jump_force * 0.5
        end
        vel.vy = -jump_force
        stance.current = Stance.JUMPING
    end

    -- Prevent falling through bottom
    local max_y = world.HEIGHT * world.BLOCK_SIZE
    if pos.y > max_y then
        pos.y = max_y
        vel.vy = 0
        if stance.current == Stance.JUMPING or stance.current == Stance.FALLING then
            stance.current = Stance.STANDING
        end
    end
end

function PlayerSystem.draw(self)
    local pos = self.components.position
    local vis = self.components.visual

    local camera = Systems.get("camera")
    local camera_x, camera_y = camera:get_offset()

    love.graphics.setColor(vis.color)
    love.graphics.rectangle("fill",
        pos.x - camera_x - vis.width / 2,
        pos.y - camera_y - vis.height / 2,
        vis.width,
        vis.height)
end

function PlayerSystem.keypressed(self, key)
    -- Hotbar selection
    local num = tonumber(key)
    if num and num >= 1 and num <= self.components.inventory.hotbar_size then
        self.components.inventory.selected_slot = num
    end

    -- Layer switching
    if key == "q" then
        local target_layer = math.max(-1, self.components.position.z - 1)
        if self.can_switch_layer(self, target_layer) then
            self.components.position.z = target_layer
            self.components.layer.current_layer = target_layer
        end
    elseif key == "e" then
        local target_layer = math.min(1, self.components.position.z + 1)
        if self.can_switch_layer(self, target_layer) then
            self.components.position.z = target_layer
            self.components.layer.current_layer = target_layer
        end
    end

    if G:debug() then
        -- Debug: adjust omnitool tier
        if key == "=" or key == "+" then
            self.components.omnitool.tier = self.components.omnitool.tier + 1
        elseif key == "-" or key == "_" then
            self.components.omnitool.tier = math.max(0, self.components.omnitool.tier - 1)
        end
    end
end

function PlayerSystem.can_switch_layer(self, target_layer)
    if target_layer < -1 or target_layer > 1 then -- TODO constants for MIN and MAX layers
        return false
    end

    return not self.check_collision(self, self.components.position.x, self.components.position.y, target_layer)
end

function PlayerSystem.check_collision(self, x, y, layer)
    local world = Systems.get("world")
    local collider = self.components.collider

    local left = x - collider.width / 2
    local right = x + collider.width / 2
    local top = y - collider.height / 2
    local bottom = y + collider.height / 2

    local left_col = math.floor(left / world.BLOCK_SIZE)
    local right_col = math.floor((right - EPSILON) / world.BLOCK_SIZE)
    local top_row = math.floor(top / world.BLOCK_SIZE)
    local bottom_row = math.floor((bottom - EPSILON) / world.BLOCK_SIZE)

    for c = left_col, right_col do
        for r = top_row, bottom_row do
            local block_def = world:get_block_def(layer, c, r)
            if block_def and block_def.solid then
                return true
            end
        end
    end

    return false
end

-- Inventory management
function PlayerSystem.add_to_inventory(self, block_id, count)
    local inv = self.components.inventory
    count = count or 1

    if count <= 0 then
        return true
    end

    -- Try to stack with existing slots
    for i = 1, inv.hotbar_size do
        local slot = inv.slots[i]
        if slot and slot.block_id == block_id then
            local space = inv.max_stack - slot.count
            if space > 0 then
                local to_add = math.min(space, count)
                slot.count = slot.count + to_add
                count = count - to_add

                if count == 0 then
                    return true
                end
            end
        end
    end

    -- Find empty slots
    while count > 0 do
        local empty_slot = nil
        for i = 1, inv.hotbar_size do
            if not inv.slots[i] then
                empty_slot = i
                break
            end
        end

        if not empty_slot then
            return false
        end

        local to_add = math.min(inv.max_stack, count)
        inv.slots[empty_slot] = {
            block_id = block_id,
            count = to_add,
        }
        count = count - to_add
    end

    return true
end

function PlayerSystem.remove_from_selected(self, count)
    local inv = self.components.inventory
    count = count or 1
    local slot = inv.slots[inv.selected_slot]

    if not slot then
        return 0
    end

    local removed = math.min(count, slot.count)
    slot.count = slot.count - removed

    if slot.count <= 0 then
        inv.slots[inv.selected_slot] = nil
    end

    return removed
end

function PlayerSystem.get_selected_block_id(self)
    local inv = self.components.inventory
    local slot = inv.slots[inv.selected_slot]
    if slot then
        return slot.block_id
    end
    return nil
end

function PlayerSystem.get_position(self)
    return self.components.position.x, self.components.position.y, self.components.position.z
end

function PlayerSystem.get_omnitool_tier(self)
    return self.components.omnitool.tier
end

return PlayerSystem
