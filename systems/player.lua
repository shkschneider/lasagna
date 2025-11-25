local Object = require "core.object"
local VectorComponent = require "components.vector"
local PhysicsComponent = require "components.physics"
local Layer = require "components.layer"
local Inventory = require "components.inventory"
local Omnitool = require "components.omnitool"
local Stance = require "components.stance"
local Health = require "components.health"
local Stamina = require "components.stamina"
local PhysicsSystem = require "systems.physics"
local Registry = require "registries"
local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

local Player = Object.new {
    id = "player",
    priority = 20,
    -- Movement constants TODO control?
    MOVE_SPEED = 150,
    JUMP_FORCE = 300,
    -- Fall damage constants TODO gravity?
    SAFE_FALL_BLOCKS = 4,  -- 2x player height
    FALL_DAMAGE_PER_BLOCK = 5,
    DAMAGE_DISPLAY_DURATION = 0.5,
    -- Stamina constants TODO move
    STAMINA_REGEN_RATE = 1,  -- per second
    STAMINA_RUN_COST = 2.5,  -- per second
    STAMINA_JUMP_COST = 5,   -- per jump
}

function Player.load(self)
    local x, y, z = G.world:find_spawn_position(LAYER_DEFAULT)

    -- Initialize player components
    self.position = VectorComponent.new(x, y, z)
    self.velocity = VectorComponent.new(0, 0)
    -- Disable automatic velocity application for player (complex collision handling)
    self.physics = PhysicsComponent.new(800, 0.95)
    -- Disable automatic physics for player (complex collision handling)
    self.physics.enabled = false
    -- Player dimensions (width and height for collision and rendering)
    self.width = BLOCK_SIZE
    self.height = BLOCK_SIZE * 2
    -- Visual properties for rendering
    self.color = { 1, 1, 1, 1 }
    self.layer = Layer.new(layer)
    self.inventory = Inventory.new()
    self.omnitool = Omnitool.new()
    self.stance = Stance.new(Stance.STANDING)
    self.stance.crouched = false
    self.health = Health.new(100, 100)
    -- Health regen disabled by default (0 regen_rate)
    self.stamina = Stamina.new(100, 100, Player.STAMINA_REGEN_RATE)

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
    -- TODO control?

    if G.debug.enabled then
        local px, py = G.world:world_to_block(self.position.x, self.position.y)
        Log.debug("Player:", px, py)
        -- Add weapon items to slots 2 and 3 (slot 1 is for omnitool)
        G.player:add_item_to_inventory(ITEMS.GUN, 1)
        G.player:add_item_to_inventory(ITEMS.ROCKET_LAUNCHER, 1)
    end

    Object.load(self)
end

function Player.update(self, dt)
    local pos = self.position
    local vel = self.velocity
    local phys = self.physics
    local stance = self.stance

    -- Update damage timer
    if self.damage_timer > 0 then
        self.damage_timer = self.damage_timer - dt
    end

    -- Call component updates via Object recursion
    -- This handles stamina regen and health regen (if enabled)
    Object.update(self, dt)

    -- Delegate to control system for input handling
    if self.control then
        self.control:update(dt)
    end

    -- Check if on ground first (using physics system)
    local on_ground = PhysicsSystem.is_on_ground(G.world, pos, self.width, self.height)

    -- Track fall start position when first becoming airborne
    if not on_ground then
        if self.fall_start_y == nil then
            self.fall_start_y = pos.y
        end
    end

    -- Apply gravity (using physics system)
    PhysicsSystem.apply_gravity(vel, phys.gravity, dt)

    -- Apply horizontal velocity with collision (using physics system)
    local hit_wall, new_x = PhysicsSystem.apply_horizontal_movement(
        G.world, pos, vel, self.width, self.height, dt
    )
    pos.x = new_x

    -- Apply vertical velocity with collision (using physics system)
    local velocity_modifier = stance.crouched and 0.5 or 1
    local landed, hit_ceiling, new_y = PhysicsSystem.apply_vertical_movement(
        G.world, pos, vel, self.width, self.height, velocity_modifier, dt
    )

    -- Always update position - apply_vertical_movement returns the correct y position
    -- whether on ground (snapped to ground) or in air (new_y from movement)
    pos.y = new_y

    on_ground = landed

    -- Clamp to world bounds
    local clamped_to_ground = PhysicsSystem.clamp_to_world(G.world, pos, vel, self.height)
    on_ground = on_ground or clamped_to_ground

    -- Update stance based on current state
    if on_ground then
        -- Calculate fall damage on landing if we were airborne
        if not self.health.invincible and self.fall_start_y ~= nil then
            local fall_distance = pos.y - self.fall_start_y
            local fall_blocks = fall_distance / BLOCK_SIZE
            -- Safe fall is 4 blocks (2x player height, since player is 2 blocks tall)
            if fall_blocks > Player.SAFE_FALL_BLOCKS then
                local excess_blocks = fall_blocks - Player.SAFE_FALL_BLOCKS
                local damage = math.floor(excess_blocks * Player.FALL_DAMAGE_PER_BLOCK)
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
        if vel.y > 0 then
            -- Moving downward - falling
            if stance.current == Stance.JUMPING or stance.current == Stance.STANDING then
                stance.current = Stance.FALLING
            end
        end
        -- Keep JUMPING stance while moving upward (vel.y < 0)
    end
end

function Player.draw(self)
    local pos = self.position

    local camera_x, camera_y = G.camera:get_offset()

    -- Draw player using direct properties
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill",
        pos.x - camera_x - self.width / 2,
        pos.y - camera_y - self.height / 2,
        self.width,
        self.height)

    -- Draw red border if recently damaged
    if self.damage_timer > 0 then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line",
            pos.x - camera_x - self.width / 2,
            pos.y - camera_y - self.height / 2,
            self.width,
            self.height)
    end

    Object.draw(self)
end

function Player.can_switch_layer(self, target_layer)
    if target_layer < -1 or target_layer > 1 then -- TODO constants for MIN and MAX layers
        return false
    end

    return not PhysicsSystem.check_collision(G.world, self.position.x, self.position.y, target_layer, self.width, self.height)
end

-- Inventory management
function Player.add_to_inventory(self, block_id, count)
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

function Player.add_item_to_inventory(self, item_id, count)
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

function Player.remove_from_selected(self, count)
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

function Player.get_selected_block_id(self)
    local inv = self.inventory
    local slot = inv.slots[inv.selected_slot]
    if slot then
        return slot.block_id
    end
    return nil
end

function Player.upgrade(self, upOrDown)
    assert(type(upOrDown) == "number")
    if upOrDown > 0 then
        self.omnitool.tier = math.min(self.omnitool.tier + 1, self.omnitool.max)
        Log.info("Player", "upgrade", self.omnitool.tier)
    elseif upOrDown < 0 then
        self.omnitool.tier = math.max(self.omnitool.min, self.omnitool.tier - 1)
        Log.info("Player", "downgrade", self.omnitool.tier)
    else
        assert(false)
    end
end

function Player.get_position(self)
    return self.position.x, self.position.y, self.position.z
end

function Player.get_omnitool_tier(self)
    return self.omnitool.tier
end

function Player.is_on_ground(self)
    return PhysicsSystem.is_on_ground(G.world, self.position, self.width, self.height)
end

function Player.can_stand_up(self)
    local pos = self.position
    local target_y = pos.y - BLOCK_SIZE / 2  -- Position after standing
    local top_y = target_y - BLOCK_SIZE  -- Top of standing height
    local left_col = math.floor((pos.x - self.width / 2) / BLOCK_SIZE)
    local right_col = math.floor((pos.x + self.width / 2 - math.eps) / BLOCK_SIZE)
    local top_row = math.floor(top_y / BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = G.world:get_block_def(pos.z, c, top_row)
        if block_def and block_def.solid then
            return false
        end
    end

    return true
end

function Player.hit(self, damage)
    if not self.health then
        return
    end

    -- Apply damage
    self.health.current = math.max(0, self.health.current - damage)

    -- Set damage timer for visual effect
    self.damage_timer = Player.DAMAGE_DISPLAY_DURATION
end

function Player.is_dead(self)
    return self.health and self.health.current <= 0
end

function Player.consume_stamina(self, amount)
    if not self.stamina then
        return false
    end

    if self.stamina.current >= amount then
        self.stamina.current = math.max(0, self.stamina.current - amount)
        return true
    end

    return false
end

function Player.has_stamina(self, amount)
    return self.stamina and self.stamina.current >= amount
end

return Player
