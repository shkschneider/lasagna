-- Player System
-- Manages player entity and player-specific logic

require "lib"
local log = require "lib.log"

local Object = require "core.object"
local Systems = require "core.systems"
local Position = require "components.position"
local Velocity = require "components.velocity"
local Physics = require "components.physics"
local Collider = require "components.collider"
local Visual = require "components.visual"
local Layer = require "components.layer"
local Inventory = require "components.inventory"
local Omnitool = require "components.omnitool"
local Stance = require "components.stance"
local Health = require "components.health"
local Stamina = require "components.stamina"
local Registry = require "registries"

local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

local PlayerSystem = Object.new {
    id = "player",
    priority = 20,
    -- Movement constants
    MOVE_SPEED = 150,
    JUMP_FORCE = 300,
    -- Fall damage constants
    SAFE_FALL_BLOCKS = 4,  -- 2x player height
    FALL_DAMAGE_PER_BLOCK = 5,
    DAMAGE_DISPLAY_DURATION = 0.5,
    -- Stamina constants
    STAMINA_REGEN_RATE = 1,  -- per second
    STAMINA_RUN_COST = 2.5,  -- per second
    STAMINA_JUMP_COST = 5,   -- per jump
}

function PlayerSystem.load(self)
    local world = Systems.get("world")
    local x, y, z = world:find_spawn_position(LAYER_DEFAULT)

    -- Initialize player components
    self.position = Position.new(x, y, z)
    self.velocity = Velocity.new(0, 0)
    self.physics = Physics.new(800, 0.95)
    self.collider = Collider.new(BLOCK_SIZE, BLOCK_SIZE * 2)
    self.visual = Visual.new({1, 1, 1, 1}, BLOCK_SIZE, BLOCK_SIZE * 2)
    self.layer = Layer.new(layer)
    self.inventory = Inventory.new()
    self.omnitool = Omnitool.new()
    self.stance = Stance.new(Stance.STANDING)
    self.stance.crouched = false
    self.health = Health.new(100, 100)
    self.stamina = Stamina.new(100, 100)

    -- Fall damage tracking
    self.fall_start_y = nil
    self.damage_timer = 0

    -- Initialize inventory slots
    for i = 1, self.inventory.hotbar_size do
        self.inventory.slots[i] = nil
    end

    -- Add omnitool to slot 1
    self:add_item_to_inventory(ITEMS.OMNITOOL, 1)

    -- Initialize control system
    self.control = require "systems.control"

    local px, py = world:world_to_block(self.position.x, self.position.y)
    log.debug("Player:", px, py)

    Object.load(self)
end

function PlayerSystem.update(self, dt)
    local world = Systems.get("world")

    local pos = self.position
    local vel = self.velocity
    local phys = self.physics
    local col = self.collider
    local stance = self.stance
    local vis = self.visual
    local stamina = self.stamina

    -- Update damage timer
    if self.damage_timer > 0 then
        self.damage_timer = self.damage_timer - dt
    end

    -- Regenerate stamina
    if stamina.current < stamina.max then
        stamina.current = math.min(stamina.max, stamina.current + PlayerSystem.STAMINA_REGEN_RATE * dt)
    end

    -- Delegate to control system for input handling
    if self.control then
        self.control:update(dt)
    end

    -- Check if on ground first
    local on_ground = self:is_on_ground()

    -- Track fall start position when first becoming airborne
    if not on_ground then
        if self.fall_start_y == nil then
            self.fall_start_y = pos.y
        end
    end

    -- Gravity always applies
    vel.vy = vel.vy + phys.gravity * dt

    -- Apply horizontal velocity with collision
    local new_x = pos.x + vel.vx * dt
    local hit_wall = false

    if vel.vx ~= 0 then
        local check_col
        if vel.vx > 0 then
            check_col = math.floor((new_x + col.width / 2) / BLOCK_SIZE)
        else
            check_col = math.floor((new_x - col.width / 2) / BLOCK_SIZE)
        end

        local top_row = math.floor((pos.y - col.height / 2) / BLOCK_SIZE)
        local bottom_row = math.floor((pos.y + col.height / 2 - EPSILON) / BLOCK_SIZE)

        for row = top_row, bottom_row do
            local block_def = world:get_block_def(pos.z, check_col, row)
            if block_def and block_def.solid then
                hit_wall = true
                if vel.vx > 0 then
                    pos.x = check_col * BLOCK_SIZE - col.width / 2
                else
                    pos.x = (check_col + 1) * BLOCK_SIZE + col.width / 2
                end
                break
            end
        end
    end

    if not hit_wall then
        pos.x = new_x
    end

    -- Apply vertical velocity with collision
    local new_y = pos.y + (vel.vy * (stance.crouched and 0.5 or 1)) * dt

    -- Ground collision
    local was_on_ground = on_ground
    on_ground = false
    local bottom_y = new_y + col.height / 2
    local left_col = math.floor((pos.x - col.width / 2) / BLOCK_SIZE)
    local right_col = math.floor((pos.x + col.width / 2 - EPSILON) / BLOCK_SIZE)
    local bottom_row = math.floor(bottom_y / BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, bottom_row)
        if block_def and block_def.solid and vel.vy >= 0 then
            pos.y = bottom_row * BLOCK_SIZE - col.height / 2
            vel.vy = 0
            on_ground = true
            new_y = pos.y
            break
        end
    end

    -- Ceiling collision
    local top_y = new_y - col.height / 2
    local top_row = math.floor(top_y / BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, top_row)
        if block_def and block_def.solid and vel.vy < 0 then
            pos.y = (top_row + 1) * BLOCK_SIZE + col.height / 2
            vel.vy = 0
            new_y = pos.y
            break
        end
    end

    if not on_ground then
        pos.y = new_y
    end

    -- Prevent falling through bottom
    local max_y = world.HEIGHT * BLOCK_SIZE
    if pos.y > max_y then
        pos.y = max_y
        vel.vy = 0
        on_ground = true
    end

    -- Update stance based on current state
    if on_ground then
        -- Calculate fall damage on landing if we were airborne
        if not self.health.invincible and self.fall_start_y ~= nil then
            local fall_distance = pos.y - self.fall_start_y
            local fall_blocks = fall_distance / BLOCK_SIZE
            -- Safe fall is 4 blocks (2x player height, since player is 2 blocks tall)
            if fall_blocks > PlayerSystem.SAFE_FALL_BLOCKS then
                local excess_blocks = fall_blocks - PlayerSystem.SAFE_FALL_BLOCKS
                local damage = math.floor(excess_blocks * PlayerSystem.FALL_DAMAGE_PER_BLOCK)
                if damage > 0 then
                    self:hit(damage)
                end
            end
            self.fall_start_y = nil
        end

        if stance.current == Stance.JUMPING or stance.current == Stance.FALLING then
            stance.current = Stance.STANDING
        end
    else
        -- In air - update based on vertical velocity
        if vel.vy > 0 then
            -- Moving downward - falling
            if stance.current == Stance.JUMPING or stance.current == Stance.STANDING then
                stance.current = Stance.FALLING
            end
        end
        -- Keep JUMPING stance while moving upward (vel.vy < 0)
    end

    Object.update(self, dt)
end

function PlayerSystem.draw(self)
    local pos = self.position
    local vis = self.visual

    local camera = Systems.get("camera")
    local camera_x, camera_y = camera:get_offset()

    -- Draw player
    love.graphics.setColor(vis.color)
    love.graphics.rectangle("fill",
        pos.x - camera_x - vis.width / 2,
        pos.y - camera_y - vis.height / 2,
        vis.width,
        vis.height)

    -- Draw red border if recently damaged
    if self.damage_timer > 0 then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line",
            pos.x - camera_x - vis.width / 2,
            pos.y - camera_y - vis.height / 2,
            vis.width,
            vis.height)
    end

    Object.draw(self)
end

function PlayerSystem.keypressed(self, key)
    Object.keypressed(self, key)
end

function PlayerSystem.can_switch_layer(self, target_layer)
    if target_layer < -1 or target_layer > 1 then -- TODO constants for MIN and MAX layers
        return false
    end

    return not self.check_collision(self, self.position.x, self.position.y, target_layer)
end

function PlayerSystem.check_collision(self, x, y, layer)
    local world = Systems.get("world")
    local collider = self.collider

    local left = x - collider.width / 2
    local right = x + collider.width / 2
    local top = y - collider.height / 2
    local bottom = y + collider.height / 2

    local left_col = math.floor(left / BLOCK_SIZE)
    local right_col = math.floor((right - EPSILON) / BLOCK_SIZE)
    local top_row = math.floor(top / BLOCK_SIZE)
    local bottom_row = math.floor((bottom - EPSILON) / BLOCK_SIZE)

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
    local inv = self.inventory
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

function PlayerSystem.add_item_to_inventory(self, item_id, count)
    local inv = self.inventory
    count = count or 1

    if count <= 0 then
        return true
    end

    -- Try to stack with existing slots
    for i = 1, inv.hotbar_size do
        local slot = inv.slots[i]
        if slot and slot.item_id == item_id then
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
            item_id = item_id,
            count = to_add,
        }
        count = count - to_add
    end

    return true
end

function PlayerSystem.remove_from_selected(self, count)
    local inv = self.inventory
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
    local inv = self.inventory
    local slot = inv.slots[inv.selected_slot]
    if slot then
        return slot.block_id
    end
    return nil
end

function PlayerSystem.upgrade(self, upOrDown)
    assert(type(upOrDown) == "number")
    if upOrDown > 0 then
        self.omnitool.tier = math.min(self.omnitool.tier + 1, self.omnitool.max)
        log.info("Player", "upgrade", self.omnitool.tier)
    elseif upOrDown < 0 then
        self.omnitool.tier = math.max(self.omnitool.min, self.omnitool.tier - 1)
        log.info("Player", "downgrade", self.omnitool.tier)
    else
        assert(false)
    end
end

function PlayerSystem.get_position(self)
    return self.position.x, self.position.y, self.position.z
end

function PlayerSystem.get_omnitool_tier(self)
    return self.omnitool.tier
end

function PlayerSystem.is_on_ground(self)
    local world = Systems.get("world")
    local pos = self.position
    local col = self.collider
    local vel = self.velocity

    -- Check if there's ground directly below the player
    local bottom_y = pos.y + col.height / 2
    local left_col = math.floor((pos.x - col.width / 2) / BLOCK_SIZE)
    local right_col = math.floor((pos.x + col.width / 2 - EPSILON) / BLOCK_SIZE)
    local bottom_row = math.floor(bottom_y / BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, bottom_row)
        if block_def and block_def.solid then
            return true
        end
    end

    return false
end

function PlayerSystem.can_stand_up(self)
    local world = Systems.get("world")
    local pos = self.position
    local col = self.collider

    -- Check if there's space above for standing (need to check one extra block height)
    local target_y = pos.y - BLOCK_SIZE / 2  -- Position after standing
    local top_y = target_y - BLOCK_SIZE  -- Top of standing height
    local left_col = math.floor((pos.x - col.width / 2) / BLOCK_SIZE)
    local right_col = math.floor((pos.x + col.width / 2 - EPSILON) / BLOCK_SIZE)
    local top_row = math.floor(top_y / BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, top_row)
        if block_def and block_def.solid then
            return false
        end
    end

    return true
end

function PlayerSystem.hit(self, damage)
    if not self.health then
        return
    end

    -- Apply damage
    self.health.current = math.max(0, self.health.current - damage)

    -- Set damage timer for visual effect
    self.damage_timer = PlayerSystem.DAMAGE_DISPLAY_DURATION
end

function PlayerSystem.is_dead(self)
    return self.health and self.health.current <= 0
end

function PlayerSystem.consume_stamina(self, amount)
    if not self.stamina then
        return false
    end

    if self.stamina.current >= amount then
        self.stamina.current = math.max(0, self.stamina.current - amount)
        return true
    end

    return false
end

function PlayerSystem.has_stamina(self, amount)
    return self.stamina and self.stamina.current >= amount
end

return PlayerSystem
