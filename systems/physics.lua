-- Physics system
-- Coordinates physics calculations and collision detection

local Object = require "core.object"

local Physics = Object.new {
    id = "physics_system",
    priority = 15,  -- Run before player system (priority 20)
}

-- Check AABB collision with world blocks
-- Returns true if collision occurs, false otherwise
function Physics.check_collision(world, x, y, layer, width, height)
    local left = x - width / 2
    local right = x + width / 2
    local top = y - height / 2
    local bottom = y + height / 2

    local left_col = math.floor(left / BLOCK_SIZE)
    local right_col = math.floor((right - math.eps) / BLOCK_SIZE)
    local top_row = math.floor(top / BLOCK_SIZE)
    local bottom_row = math.floor((bottom - math.eps) / BLOCK_SIZE)

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

-- Check if an entity is on the ground
function Physics.is_on_ground(world, pos, width, height)
    local bottom_y = pos.y + height / 2
    local left_col = math.floor((pos.x - width / 2) / BLOCK_SIZE)
    local right_col = math.floor((pos.x + width / 2 - math.eps) / BLOCK_SIZE)
    local bottom_row = math.floor(bottom_y / BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, bottom_row)
        if block_def and block_def.solid then
            return true
        end
    end

    return false
end

-- Check if there's space above for standing
function Physics.can_stand_up(world, pos, width)
    local target_y = pos.y - BLOCK_SIZE / 2  -- Position after standing
    local top_y = target_y - BLOCK_SIZE  -- Top of standing height
    local left_col = math.floor((pos.x - width / 2) / BLOCK_SIZE)
    local right_col = math.floor((pos.x + width / 2 - math.eps) / BLOCK_SIZE)
    local top_row = math.floor(top_y / BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, top_row)
        if block_def and block_def.solid then
            return false
        end
    end

    return true
end

-- Apply gravity to velocity
function Physics.apply_gravity(vel, gravity, dt)
    vel.vy = vel.vy + gravity * dt
end

-- Apply horizontal movement with collision detection
-- Returns whether a wall was hit and the new x position
function Physics.apply_horizontal_movement(world, pos, vel, width, height, dt)
    local new_x = pos.x + vel.vx * dt
    local hit_wall = false

    if vel.vx ~= 0 then
        local check_col
        if vel.vx > 0 then
            check_col = math.floor((new_x + width / 2) / BLOCK_SIZE)
        else
            check_col = math.floor((new_x - width / 2) / BLOCK_SIZE)
        end

        local top_row = math.floor((pos.y - height / 2) / BLOCK_SIZE)
        local bottom_row = math.floor((pos.y + height / 2 - math.eps) / BLOCK_SIZE)

        for row = top_row, bottom_row do
            local block_def = world:get_block_def(pos.z, check_col, row)
            if block_def and block_def.solid then
                hit_wall = true
                if vel.vx > 0 then
                    new_x = check_col * BLOCK_SIZE - width / 2
                else
                    new_x = (check_col + 1) * BLOCK_SIZE + width / 2
                end
                break
            end
        end
    end

    return hit_wall, new_x
end

-- Apply vertical movement with collision detection
-- Returns on_ground status, whether ceiling was hit, and the new y position
function Physics.apply_vertical_movement(world, pos, vel, width, height, velocity_modifier, dt)
    local new_y = pos.y + (vel.vy * velocity_modifier) * dt
    local on_ground = false
    local hit_ceiling = false

    -- Ground collision
    local bottom_y = new_y + height / 2
    local left_col = math.floor((pos.x - width / 2) / BLOCK_SIZE)
    local right_col = math.floor((pos.x + width / 2 - math.eps) / BLOCK_SIZE)
    local bottom_row = math.floor(bottom_y / BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, bottom_row)
        if block_def and block_def.solid and vel.vy >= 0 then
            new_y = bottom_row * BLOCK_SIZE - height / 2
            vel.vy = 0
            on_ground = true
            break
        end
    end

    -- Ceiling collision
    local top_y = new_y - height / 2
    local top_row = math.floor(top_y / BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = world:get_block_def(pos.z, c, top_row)
        if block_def and block_def.solid and vel.vy < 0 then
            new_y = (top_row + 1) * BLOCK_SIZE + height / 2
            vel.vy = 0
            hit_ceiling = true
            break
        end
    end

    return on_ground, hit_ceiling, new_y
end

-- Clamp entity to world bounds
function Physics.clamp_to_world(world, pos, vel, height)
    local max_y = world.HEIGHT * BLOCK_SIZE
    local on_ground = false

    if pos.y > max_y then
        pos.y = max_y
        vel.vy = 0
        on_ground = true
    end

    return on_ground
end

-- Update player physics (called by player system)
-- This handles the full physics update for the player entity
function Physics.update_player(self, player, dt)
    local pos = player.position
    local vel = player.velocity
    local phys = player.physics
    local width = player.width or BLOCK_SIZE
    local height = player.height or BLOCK_SIZE * 2
    local stance = player.stance

    -- Apply gravity
    Physics.apply_gravity(vel, phys.gravity, dt)

    -- Apply horizontal velocity with collision
    local hit_wall, new_x = Physics.apply_horizontal_movement(
        G.world, pos, vel, width, height, dt
    )
    pos.x = new_x

    -- Apply vertical velocity with collision
    local velocity_modifier = stance.crouched and 0.5 or 1
    local on_ground, hit_ceiling, new_y = Physics.apply_vertical_movement(
        G.world, pos, vel, width, height, velocity_modifier, dt
    )

    if not on_ground then
        pos.y = new_y
    end

    -- Clamp to world bounds
    local clamped_to_ground = Physics.clamp_to_world(G.world, pos, vel, height)

    return on_ground or clamped_to_ground
end

return Physics
