local Love = require "core.love"
local Object = require "core.object"
local Control = require "src.entities.control"
local Physics = require "src.world.physics"
local Inventory = require "src.entities.inventory"
local Stack = require "src.entities.stack"
local Weapon = require "src.entities.weapon"
local Jetpack = require "src.entities.jetpack"
local Vector = require "src.game.vector"
local Omnitool = require "src.entities.omnitool"
local Stance = require "src.entities.stance"
local Health = require "src.entities.health"
local Armor = require "src.entities.armor"
local Stamina = require "src.entities.stamina"
local Registry = require "src.registries"
local ITEMS = Registry.items()

Player = Object {
    id = "player",
    priority = 20,
    -- Constants
    SAFE_FALL_BLOCKS = 4,  -- 2x player height
    FALL_DAMAGE_PER_BLOCK = 5,
    STAMINA_REGEN_RATE = 1,  -- per second
    HOTBAR_SIZE = 9,
    BACKPACK_SIZE = 27,  -- 3 rows of 9
}

function Player.load(self)
    self.width = BLOCK_SIZE
    self.height = BLOCK_SIZE * 2
    self.color = { 1, 1, 1, 1 }

    -- Animation state
    self.animation = {
        time = 0,           -- Time accumulator for animation
        frame = 0,          -- Current frame index
        fps = 10,           -- Frames per second for animation
        facing_right = true, -- Direction player is facing
    }

    -- Sytems
    self.hotbar = Inventory.new(self.HOTBAR_SIZE)
    self.backpack = Inventory.new(self.BACKPACK_SIZE)
    self.control = Control.new()
    self.weapon = Weapon
    self.jetpack = G.debug and Jetpack or nil

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
    self.armor = Armor.new(G.debug and 50 or 0, 100)
    self.stamina = Stamina.new(100, 100, Player.STAMINA_REGEN_RATE)

    -- Fall damage tracking
    self.fall_start_y = nil
    self.inventory_open = false  -- Whether the full inventory (backpack) is displayed

    -- Cached ground state (updated after physics resolution each frame)
    -- Initialize based on actual spawn position
    self.on_ground = Physics.is_on_ground(G.world, self.position, self.width, self.height)
    if not self.on_ground then
        Log.warning("Player not on ground!")
    end

    -- Items
    self.hotbar:set_slot(1, Stack.new(ITEMS.OMNITOOL, 1, "item"))
    if G.debug then
        Log.debug(G.world:world_to_block(self.position.x, self.position.y))
        self.hotbar:set_slot(2, Stack.new(ITEMS.GUN, 1, "item"))
        self.hotbar:set_slot(3, Stack.new(ITEMS.ROCKET_LAUNCHER, 1, "item"))
    end

    Love.load(self)
end

function Player.update(self, dt)
    if self:is_dead() then return end
    local pos = self.position
    local vel = self.velocity
    local stance = self.stance

    -- Update animation based on movement
    if vel.x ~= 0 then
        -- Update facing direction
        self.animation.facing_right = vel.x > 0
        
        -- Update animation time and frame
        self.animation.time = self.animation.time + dt
        if self.animation.time >= (1.0 / self.animation.fps) then
            self.animation.frame = self.animation.frame + 1
            self.animation.time = 0
        end
    else
        -- Reset animation when not moving
        self.animation.time = self.animation.time + dt
        if self.animation.time >= (1.0 / (self.animation.fps / 2)) then -- Idle animates slower
            self.animation.frame = self.animation.frame + 1
            self.animation.time = 0
        end
    end

    -- Manually update health, armor, and stamina components
    self.health:update(dt)
    self.armor:update(dt)
    self.stamina:update(dt)

    -- Call other component updates via Object recursion
    Love.update(self, dt)

    -- Check if on ground first (using physics system)
    local on_ground = Physics.is_on_ground(G.world, pos, self.width, self.height)

    -- Track fall start position - update to highest point reached (lowest Y)
    if not on_ground then
        if self.fall_start_y == nil or pos.y < self.fall_start_y then
            self.fall_start_y = pos.y
        end
    end

    -- Apply gravity (using physics system with player's gravity)
    -- Skip gravity when jetpack is active
    if not self.control.jetpack_thrusting then
        Physics.apply_gravity(vel, self.gravity, dt)
    end

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

    -- Capture vertical velocity before physics resolution (for fall damage calculation)
    local impact_velocity = vel.y

    -- Apply vertical velocity with collision (using physics system)
    -- Don't apply crouch velocity modifier when jetpack is thrusting (would reduce thrust effectiveness)
    local velocity_modifier = (stance.crouched and not self.control.jetpack_thrusting) and 0.5 or 1
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
                -- Linear damage scaling with height and velocity factor
                local damage = math.clamp(0, (impact_velocity * excess_blocks) / self.gravity, self.health.max + self.armor.max)
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

    -- Determine which sprite to use based on player state
    local sprite_name = "default"
    local vel = self.velocity
    local stance = self.stance
    
    if self:is_dead() then
        sprite_name = "death_8"
    elseif self.health:is_recently_damaged() then
        sprite_name = "hurt_4"
    elseif stance.current == Stance.JUMPING then
        sprite_name = "jump_8"
    elseif stance.current == Stance.FALLING then
        sprite_name = "jump_8" -- Use jump animation for falling too
    elseif vel.x ~= 0 then
        -- Moving horizontally
        if self.control.sprinting then
            sprite_name = "run_6"
        else
            sprite_name = "walk_6"
        end
    else
        -- Standing still
        sprite_name = "idle_4"
    end
    
    -- Calculate screen position
    local screen_x = pos.x - camera_x
    local screen_y = pos.y - camera_y
    
    -- Draw sprite
    if G.ui and G.ui.sprites then
        G.ui.sprites:draw_player(
            sprite_name,
            screen_x,
            screen_y,
            self.animation.frame,
            self.animation.facing_right,
            1.0  -- scale
        )
    else
        -- Fallback to rectangle if sprites not loaded
        if self:is_dead() then
            love.graphics.setColor(1, 0, 0, 1) -- red
        else
            love.graphics.setColor(self.color)
        end
        love.graphics.rectangle("fill",
            screen_x - self.width / 2,
            screen_y - self.height / 2,
            self.width,
            self.height)
    end

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

    if self.control.jetpack_thrusting then
        local jx, jy = pos.x - camera_x,
            pos.y - camera_y + self.height / 2
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.line(jx, jy, jx, jy + BLOCK_SIZE)
    end

    -- Draw health, armor, and stamina bars (UI elements, not camera-relative)
    self.health:draw()  -- First bar
    self.armor:draw()   -- Second bar
    self.stamina:draw() -- Third bar

    Love.draw(self)
end

function Player.keypressed(self, key)
    if key == "tab" then
        self.inventory_open = not self.inventory_open
    elseif not self.inventory_open then
        Love.keypressed(self, key)
    end
end

function Player.can_switch_layer(self, target_layer)
    return G.world:can_switch_layer(target_layer)
        and not Physics.check_collision(G.world, self.position.x + 1, self.position.y + 1, target_layer, self.width - 2, self.height - 2)
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
    if not self.health then return end
    damage = self.stance.crouched and (damage / 2) or damage
    -- Armor halfs the damage
    if self.armor and self.armor.current > 0 then
        local dmg = math.min(damage, self.armor.current * 2)
        self.armor:hit(dmg / 2)
        damage = damage - dmg
    end
    -- Apply remaining damage to health
    if damage > 0 then
        self.health:hit(damage)
    end
    -- Death?
end

function Player.is_dead(self)
    return self.health and self.health.current <= 0
end

-- Inventory management - delegates to Inventory
-- Blocks go to backpack first, then hotbar
function Player.add_to_inventory(self, block_id, count)
    local stack = Stack.new(block_id, count or 1, "block")
    -- Try backpack first for blocks
    if self.backpack:can_take(stack) then
        return self.backpack:take(stack)
    end
    -- Try hotbar as fallback
    if self.hotbar:can_take(stack) then
        return self.hotbar:take(stack)
    end
    return false
end

-- Items go to hotbar first, then backpack
function Player.add_item_to_inventory(self, item_id, count)
    local stack = Stack.new(item_id, count or 1, "item")
    -- Try hotbar first for items
    if self.hotbar:can_take(stack) then
        return self.hotbar:take(stack)
    end
    -- Try backpack as fallback
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

return Player
