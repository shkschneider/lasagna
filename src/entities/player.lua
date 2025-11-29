local Love = require "core.love"
local Object = require "core.object"
local Control = require "src.entities.control"
local Physics = require "src.world.physics"
local Inventory = require "src.items.inventory"
local Weapon = require "src.items.weapon"
local Jetpack = require "src.items.jetpack"
local Vector = require "src.data.vector"
local Stack = require "src.data.stack"
local Omnitool = require "src.data.omnitool"
local Stance = require "src.data.stance"
local Health = require "src.data.health"
local Stamina = require "src.data.stamina"
local Registry = require "registries"
local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

-- Inventory constants
local HOTBAR_SIZE = 9
local BACKPACK_SIZE = 27  -- 3 rows of 9

-- UI constants for health/stamina bars
local UI_SLOT_SIZE = 60
local UI_HOTBAR_Y_OFFSET = 80
local UI_BAR_GAP = 10

local Player = Object {
    id = "player",
    priority = 20,
    -- Constants
    SAFE_FALL_BLOCKS = 4,  -- 2x player height
    FALL_DAMAGE_PER_BLOCK = 5,
    STAMINA_REGEN_RATE = 1,  -- per second
}

function Player.load(self)
    self.width = BLOCK_SIZE
    self.height = BLOCK_SIZE * 2
    self.color = { 1, 1, 1, 1 }

    -- Sytems
    self.hotbar = Inventory.new(HOTBAR_SIZE)
    self.backpack = Inventory.new(BACKPACK_SIZE)
    self.control = Control.new()
    self.weapon = Weapon
    self.jetpack = Jetpack

    -- s
    local x, y, z = G.world:find_spawn_position(LAYER_DEFAULT)
    self.position = Vector.new(x, y, z)
    self.velocity = Vector.new(0, 0)
    self.velocity.enabled = false
    self.gravity = Physics.DEFAULT_GRAVITY
    self.friction = Physics.DEFAULT_FRICTION
    self.omnitool = Omnitool.new()
    self.stance = Stance.new(Stance.STANDING)
    self.stance.crouched = false
    self.health = Health.new(100, 100)
    self.stamina = Stamina.new(100, 100, Player.STAMINA_REGEN_RATE)

    -- Fall damage tracking
    self.fall_start_y = nil

    -- Cached ground state (updated after physics resolution each frame)
    -- Initialize based on actual spawn position
    self.on_ground = Physics.is_on_ground(G.world, self.position, self.width, self.height)
    if not self.on_ground then
        Log.warn("Player not on ground!")
    end

    -- Add omnitool to hotbar slot 1
    self.hotbar:set_slot(1, Stack.new(ITEMS.OMNITOOL, 1, "item"))

    if G.debug then
        Log.debug(G.world:world_to_block(self.position.x, self.position.y))
        -- Add weapon items to hotbar slots 2 and 3
        self.hotbar:set_slot(2, Stack.new(ITEMS.GUN, 1, "item"))
        self.hotbar:set_slot(3, Stack.new(ITEMS.ROCKET_LAUNCHER, 1, "item"))
    end

    Love.load(self)
end

function Player.update(self, dt)
    local pos = self.position
    local vel = self.velocity
    local stance = self.stance

    -- Manually update health and stamina components
    self.health:update(dt)
    self.stamina:update(dt)

    -- Call other component updates via Object recursion
    Love.update(self, dt)

    -- Check if on ground first (using physics system)
    local on_ground = Physics.is_on_ground(G.world, pos, self.width, self.height)

    -- Track fall start position when first becoming airborne
    if not on_ground then
        if self.fall_start_y == nil then
            self.fall_start_y = pos.y
        end
    end

    -- Apply gravity (using physics system with player's gravity)
    Physics.apply_gravity(vel, self.gravity, dt)

    -- Apply horizontal velocity with collision (using physics system)
    local hit_wall, new_x = Physics.apply_horizontal_movement(
        G.world, pos, vel, self.width, self.height, dt
    )

    -- When crouched and on ground, prevent falling off edges
    -- Only apply the new position if there would be ground beneath it
    if stance.crouched and on_ground then
        if not Physics.would_have_ground(G.world, new_x, pos.y, pos.z, self.width, self.height) then
            -- Would fall off edge - don't move horizontally
            new_x = pos.x
        end
    end

    pos.x = new_x

    -- Apply vertical velocity with collision (using physics system)
    local velocity_modifier = stance.crouched and 0.5 or 1
    local landed, hit_ceiling, new_y = Physics.apply_vertical_movement(
        G.world, pos, vel, self.width, self.height, velocity_modifier, dt
    )

    -- Always update position - apply_vertical_movement returns the correct y position
    -- whether on ground (snapped to ground) or in air (new_y from movement)
    pos.y = new_y

    on_ground = landed

    -- Clamp to world bounds
    local clamped_to_ground = Physics.clamp_to_world(G.world, pos, vel, self.height)
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

    -- Cache ground state for next frame (used by Control)
    self.on_ground = on_ground
end

function Player.draw(self)
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

    -- Draw health and stamina bars (UI elements, not camera-relative)
    self:draw_health_bar()
    self:draw_stamina_bar()

    Love.draw(self)
end

-- Helper function to calculate bar positioning relative to hotbar
local function get_bar_layout(hotbar)
    local screen_width, screen_height = love.graphics.getDimensions()
    local hotbar_y = screen_height - UI_HOTBAR_Y_OFFSET
    local hotbar_x = (screen_width - (hotbar.size * UI_SLOT_SIZE)) / 2
    local hotbar_width = hotbar.size * UI_SLOT_SIZE
    local bar_height = BLOCK_SIZE / 4  -- 1/4 BLOCK_SIZE high
    local bar_width = hotbar_width / 2  -- Half the hotbar width
    local bar_y = hotbar_y - bar_height - UI_BAR_GAP
    return hotbar_x, bar_y, bar_width, bar_height, hotbar_width
end

-- Draw health bar UI
function Player.draw_health_bar(self)
    if not self.hotbar then return end

    local hotbar_x, bar_y, bar_width, bar_height = get_bar_layout(self.hotbar)
    local bar_x = hotbar_x  -- Aligned left

    -- Health bar background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_width, bar_height)

    -- Health bar fill
    local health = self.health
    local health_percentage = health.current / health.max
    local fill_width = bar_width * health_percentage

    -- Color based on health percentage
    if health_percentage > 0.6 then
        love.graphics.setColor(0, 1, 0, 0.8)  -- Green
    elseif health_percentage > 0.3 then
        love.graphics.setColor(1, 1, 0, 0.8)  -- Yellow
    else
        love.graphics.setColor(1, 0, 0, 0.8)  -- Red
    end
    love.graphics.rectangle("fill", bar_x, bar_y, fill_width, bar_height)
end

-- Draw stamina bar UI
function Player.draw_stamina_bar(self)
    if not self.hotbar then return end

    local hotbar_x, bar_y, bar_width, bar_height, hotbar_width = get_bar_layout(self.hotbar)
    local bar_x = hotbar_x + hotbar_width / 2  -- Aligned right (after health bar)

    -- Stamina bar background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", bar_x, bar_y, bar_width, bar_height)

    -- Stamina bar fill
    local stamina = self.stamina
    local stamina_percentage = stamina.current / stamina.max
    local fill_width = bar_width * stamina_percentage

    -- Blue color for stamina
    love.graphics.setColor(0, 0.5, 1, 0.8)  -- Blue
    love.graphics.rectangle("fill", bar_x, bar_y, fill_width, bar_height)
end

function Player.can_switch_layer(self, target_layer)
    return G.world:can_switch_layer(target_layer)
        and not Physics.check_collision(G.world, self.position.x, self.position.y, target_layer, self.width, self.height)
end

-- Inventory management - delegates to Inventory
function Player.add_to_inventory(self, block_id, count)
    local Stack = require "src.data.stack"
    local stack = Stack.new(block_id, count or 1, "block")

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

function Player.add_item_to_inventory(self, item_id, count)
    local Stack = require "src.data.stack"
    local stack = Stack.new(item_id, count or 1, "item")

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

function Player.remove_from_selected(self, count)
    return self.hotbar:remove_from_selected(count)
end

function Player.get_selected_block_id(self)
    local slot = self.hotbar:get_selected()
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
    return Physics.is_on_ground(G.world, self.position, self.width, self.height)
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

    -- Delegate to health component
    self.health:hit(damage)
end

function Player.is_dead(self)
    return self.health and self.health.current <= 0
end

return Player
