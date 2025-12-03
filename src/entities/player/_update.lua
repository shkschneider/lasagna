local Physics = require "src.world.physics"
local Stance = require "src.entities.stance"

function Player._update(self, dt)
    local pos = self.position
    local vel = self.velocity
    local stance = self.stance

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
