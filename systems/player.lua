local Love = require "core.love"
local Object = require "core.object"
local VectorComponent = require "components.vector"
local StackComponent = require "components.stack"
local StorageSystem = require "systems.storage"
local OmnitoolComponent = require "components.omnitool"
local StanceComponent = require "components.stance"
local HealthComponent = require "components.health"
local StaminaComponent = require "components.stamina"
local PhysicsSystem = require "systems.physics"
local Registry = require "registries"
local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

-- Inventory constants
local HOTBAR_SIZE = 9
local BACKPACK_SIZE = 27  -- 3 rows of 9

local PlayerSystem = Object {
    id = "player",
    priority = 20,
    -- Movement constants TODO control?
    MOVE_SPEED = 150,
    JUMP_FORCE = 300,
    -- Fall damage constants TODO gravity?
    SAFE_FALL_BLOCKS = 4,  -- 2x player height
    FALL_DAMAGE_PER_BLOCK = 5,
    -- Stamina constants TODO move
    STAMINA_REGEN_RATE = 1,  -- per second
}

function PlayerSystem.load(self)
    local x, y, z = G.world:find_spawn_position(LAYER_DEFAULT)

    -- Initialize player as an entity with position and velocity
    -- position.z is used as the layer
    self.position = VectorComponent.new(x, y, z)
    self.velocity = VectorComponent.new(0, 0)
    -- Disable automatic velocity application for player (uses custom collision handling)
    self.velocity.enabled = false
    -- Physics properties (gravity and friction) - player handles these manually via PhysicsSystem
    self.gravity = PhysicsSystem.DEFAULT_GRAVITY
    self.friction = PhysicsSystem.DEFAULT_FRICTION
    -- Player dimensions (width and height for collision and rendering)
    self.width = BLOCK_SIZE
    self.height = BLOCK_SIZE * 2
    -- Visual properties for rendering
    self.color = { 1, 1, 1, 1 }
    -- Player storage: hotbar (9 slots) and backpack (3x9 = 27 slots)
    self.hotbar = StorageSystem.new(HOTBAR_SIZE)
    self.backpack = StorageSystem.new(BACKPACK_SIZE)
    self.omnitool = OmnitoolComponent.new()
    self.stance = StanceComponent.new(StanceComponent.STANDING)
    self.stance.crouched = false
    self.health = HealthComponent.new(100, 100)
    -- Health regen disabled by default (0 regen_rate)
    self.stamina = StaminaComponent.new(100, 100, PlayerSystem.STAMINA_REGEN_RATE)

    -- Fall damage tracking
    self.fall_start_y = nil

    -- Cached ground state (updated after physics resolution each frame)
    -- Initialize based on actual spawn position
    self.on_ground = PhysicsSystem.is_on_ground(G.world, self.position, self.width, self.height)
    if not self.on_ground then
        Log.warn("Player not on ground!")
    end

    -- Add omnitool to hotbar slot 1
    self.hotbar:set_slot(1, StackComponent.new(ITEMS.OMNITOOL, 1, "item"))

    -- Initialize control system
    self.control = require "systems.control"
    -- TODO control?

    if G.debug then
        local px, py = G.world:world_to_block(self.position.x, self.position.y)
        Log.debug("Player:", px, py)
        -- Add weapon items to hotbar slots 2 and 3
        self.hotbar:set_slot(2, StackComponent.new(ITEMS.GUN, 1, "item"))
        self.hotbar:set_slot(3, StackComponent.new(ITEMS.ROCKET_LAUNCHER, 1, "item"))
    end

    Love.load(self)
end

function PlayerSystem.update(self, dt)
    local pos = self.position
    local vel = self.velocity
    local stance = self.stance

    -- Call component updates via Object recursion
    -- This handles stamina regen, health regen (if enabled), and damage_timer
    Love.update(self, dt)

    -- Check if on ground first (using physics system)
    local on_ground = PhysicsSystem.is_on_ground(G.world, pos, self.width, self.height)

    -- Track fall start position when first becoming airborne
    if not on_ground then
        if self.fall_start_y == nil then
            self.fall_start_y = pos.y
        end
    end

    -- Apply gravity (using physics system with player's gravity)
    PhysicsSystem.apply_gravity(vel, self.gravity, dt)

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
            if fall_blocks > PlayerSystem.SAFE_FALL_BLOCKS then
                local excess_blocks = fall_blocks - PlayerSystem.SAFE_FALL_BLOCKS
                local damage = math.floor(excess_blocks * PlayerSystem.FALL_DAMAGE_PER_BLOCK)
                if damage > 0 then
                    self:hit(damage)
                end
            end
            self.fall_start_y = nil
        end

        if stance.current == StanceComponent.JUMPING or stance.current == StanceComponent.FALLING then
            stance.current = StanceComponent.STANDING
        end
    else
        -- In air - update based on vertical velocity
        if vel.y > 0 then
            -- Moving downward - falling
            if stance.current == StanceComponent.JUMPING or stance.current == StanceComponent.STANDING then
                stance.current = StanceComponent.FALLING
            end
        end
        -- Keep JUMPING stance while moving upward (vel.y < 0)
    end

    -- Cache ground state for next frame (used by ControlSystem)
    self.on_ground = on_ground
end

function PlayerSystem.draw(self)
    local pos = self.position

    local camera_x, camera_y = G.camera:get_offset()

    -- Draw player using direct properties
    if self:is_dead() then
        love.graphics.setColor(1, 0, 0, 1) -- red
    else
        love.graphics.setColor(self.color)
    end
    love.graphics.rectangle("fill",
        pos.x - camera_x - self.width / 2,
        pos.y - camera_y - self.height / 2,
        self.width,
        self.height)

    -- Draw red border if recently damaged
    if self.health:is_recently_damaged() then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line",
            pos.x - camera_x - self.width / 2,
            pos.y - camera_y - self.height / 2,
            self.width,
            self.height)
    end

    Love.draw(self)
end

function PlayerSystem.can_switch_layer(self, target_layer)
    if target_layer < -1 or target_layer > 1 then -- TODO constants for MIN and MAX layers
        return false
    end

    return not PhysicsSystem.check_collision(G.world, self.position.x, self.position.y, target_layer, self.width, self.height)
end

-- Inventory management - delegates to InventorySystem
function PlayerSystem.add_to_inventory(self, block_id, count)
    local StackComponent = require "components.stack"
    local stack = StackComponent.new(block_id, count or 1, "block")

    -- Try hotbar first
    if self.hotbar:can_take(stack) then
        return self.hotbar:take(stack)
    end

    -- Try backpack
    if self.backpack:can_take(stack) then
        return self.backpack:take(stack)
    end

    return false
end

function PlayerSystem.add_item_to_inventory(self, item_id, count)
    local StackComponent = require "components.stack"
    local stack = StackComponent.new(item_id, count or 1, "item")

    -- Try hotbar first
    if self.hotbar:can_take(stack) then
        return self.hotbar:take(stack)
    end

    -- Try backpack
    if self.backpack:can_take(stack) then
        return self.backpack:take(stack)
    end

    return false
end

function PlayerSystem.remove_from_selected(self, count)
    return self.hotbar:remove_from_selected(count)
end

function PlayerSystem.get_selected_block_id(self)
    local slot = self.hotbar:get_selected()
    if slot then
        return slot.block_id
    end
    return nil
end

function PlayerSystem.upgrade(self, upOrDown)
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

function PlayerSystem.get_position(self)
    return self.position.x, self.position.y, self.position.z
end

function PlayerSystem.get_omnitool_tier(self)
    return self.omnitool.tier
end

function PlayerSystem.is_on_ground(self)
    return PhysicsSystem.is_on_ground(G.world, self.position, self.width, self.height)
end

function PlayerSystem.can_stand_up(self)
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

function PlayerSystem.hit(self, damage)
    if not self.health then
        return
    end

    -- Delegate to health component
    self.health:hit(damage)
end

function PlayerSystem.is_dead(self)
    return self.health and self.health.current <= 0
end

return PlayerSystem
