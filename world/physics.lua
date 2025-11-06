local Physics = {}

-- Check if entity collides with other entities at the given position
local function check_entity_collision(entity, px, py, world)
    -- Only check collision for drops with other drops
    if not world.entities then return nil end

    for _, other in ipairs(world.entities) do
        -- Don't check against self, and only check drops against drops
        if other ~= entity and other.proto and entity.proto then
            -- Check if on same layer
            if other.z == entity.z then
                -- Check AABB collision
                local overlap_x = not (px + entity.width <= other.px or px >= other.px + other.width)
                local overlap_y = not (py + entity.height <= other.py or py >= other.py + other.height)

                if overlap_x and overlap_y then
                    return other
                end
            end
        end
    end

    return nil
end

local function move_right(entity, desired_px, world)
    -- No horizontal bounds clamping for infinite world
    local right_now = math.floor(entity.px + entity.width - C.EPS)
    local right_desired = math.floor(desired_px + entity.width - C.EPS)
    local top_row = math.floor(entity.py + C.EPS)
    local bottom_row = math.floor(entity.py + entity.height - C.EPS)
    local blocked = false
    for col = right_now + 1, right_desired do
        for row = top_row, bottom_row do
            if world:is_solid(entity.z, col, row) then
                blocked = true
                desired_px = col - entity.width
                break
            end
        end
        if blocked then break end
    end
    if not blocked then
        local left_col = math.floor(desired_px + C.EPS)
        local right_col = math.floor(desired_px + entity.width - C.EPS)
        for col = left_col, right_col do
            for row = top_row, bottom_row do
                if world:is_solid(entity.z, col, row) then
                    desired_px = col - entity.width
                    blocked = true
                    break
                end
            end
            if blocked then break end
        end
    end
    if blocked then entity.vx = 0 end
    entity.px = desired_px
end

local function move_left(entity, desired_px, world)
    -- No horizontal bounds clamping for infinite world
    local left_now = math.floor(entity.px + C.EPS)
    local left_desired = math.floor(desired_px + C.EPS)
    local top_row = math.floor(entity.py + C.EPS)
    local bottom_row = math.floor(entity.py + entity.height - C.EPS)
    local blocked = false
    for col = left_desired, left_now - 1 do
        for row = top_row, bottom_row do
            if world:is_solid(entity.z, col, row) then
                blocked = true
                desired_px = col + 1
                break
            end
        end
        if blocked then break end
    end
    if not blocked then
        local left_col = math.floor(desired_px + C.EPS)
        local right_col = math.floor(desired_px + entity.width - C.EPS)
        for col = left_col, right_col do
            for row = top_row, bottom_row do
                if world:is_solid(entity.z, col, row) then
                    desired_px = col + 1
                    blocked = true
                    break
                end
            end
            if blocked then break end
        end
    end
    if blocked then entity.vx = 0 end
    entity.px = desired_px
end

local function move_down(entity, desired_py, world)
    if desired_py < 1 then desired_py = 1 end
    if desired_py > math.max(1, C.WORLD_HEIGHT - entity.height + 1) then desired_py = math.max(1, C.WORLD_HEIGHT - entity.height + 1) end
    local top_row = math.floor(entity.py + C.EPS)
    local bottom_now = math.floor(entity.py + entity.height - C.EPS)
    local bottom_desired = math.floor(desired_py + entity.height - C.EPS)
    local left_col = math.floor(entity.px + C.EPS)
    local right_col = math.floor(entity.px + entity.width - C.EPS)
    local blocked = false

    -- Check collision with blocks
    for row = bottom_now + 1, bottom_desired do
        if (row < 1 or row > C.WORLD_HEIGHT) then
            blocked = true
            desired_py = row - entity.height
            break
        end
        for col = left_col, right_col do
            if world:is_solid(entity.z, col, row) then
                blocked = true
                desired_py = row - entity.height
                break
            end
        end
        if blocked then break end
    end

    -- Check collision with other entities (drops)
    if not blocked and entity.proto then
        local colliding_entity = check_entity_collision(entity, entity.px, desired_py, world)
        if colliding_entity then
            blocked = true
            desired_py = colliding_entity.py - entity.height
        end
    end

    if not blocked then
        local top_row2 = math.floor(desired_py + C.EPS)
        local bottom_row2 = math.floor(desired_py + entity.height - C.EPS)
        for row = top_row2, bottom_row2 do
            for col = left_col, right_col do
                if world:is_solid(entity.z, col, row) then
                    desired_py = row - entity.height
                    blocked = true
                    break
                end
            end
            if blocked then break end
        end

        -- Check collision with other entities again at final position
        if not blocked and entity.proto then
            local colliding_entity = check_entity_collision(entity, entity.px, desired_py, world)
            if colliding_entity then
                blocked = true
                desired_py = colliding_entity.py - entity.height
            end
        end

        if blocked then
            entity.vy = 0
            if entity.movement_state then
                entity.movement_state = "GROUNDED"
            end
        else
            if entity.movement_state then
                entity.movement_state = "AIRBORNE"
            end
        end
    else
        entity.vy = 0
        if entity.movement_state then
            entity.movement_state = "GROUNDED"
        end
    end
    entity.py = desired_py
end

local function move_up(entity, desired_py, world)
    if desired_py < 1 then desired_py = 1 end
    if desired_py > math.max(1, C.WORLD_HEIGHT - entity.height + 1) then desired_py = math.max(1, C.WORLD_HEIGHT - entity.height + 1) end
    local top_now = math.floor(entity.py + C.EPS)
    local top_desired = math.floor(desired_py + C.EPS)
    local left_col = math.floor(entity.px + C.EPS)
    local right_col = math.floor(entity.px + entity.width - C.EPS)
    local blocked = false
    for row = top_desired, top_now - 1 do
        if (row < 1 or row > C.WORLD_HEIGHT) then
            blocked = true
            desired_py = row + 1
            break
        end
        for col = left_col, right_col do
            if world:is_solid(entity.z, col, row) then
                blocked = true
                desired_py = row + 1
                break
            end
        end
        if blocked then break end
    end
    if blocked then entity.vy = 0 end
    entity.py = desired_py
end

-- Check if drop has support below it (for spreading physics)
local function has_support_below(entity, world, check_px)
    if not entity.proto then return true end  -- Only for drops

    local check_py = entity.py + entity.height
    local left_col = math.floor(check_px + C.EPS)
    local right_col = math.floor(check_px + entity.width - C.EPS)
    local check_row = math.floor(check_py + C.EPS)

    -- Check for solid blocks below
    for col = left_col, right_col do
        if world:is_solid(entity.z, col, check_row) then
            return true
        end
    end

    -- Check for other drops below
    if world.entities then
        for _, other in ipairs(world.entities) do
            if other ~= entity and other.proto and other.z == entity.z then
                -- Check if other drop is directly below
                local overlap_x = not (check_px + entity.width <= other.px or check_px >= other.px + other.width)
                local touches_y = math.abs(check_py - other.py) < 0.1

                if overlap_x and touches_y then
                    return true
                end
            end
        end
    end

    return false
end

-- Check if position is free for drop to move to
local function is_position_free(entity, check_px, check_py, world)
    local left_col = math.floor(check_px + C.EPS)
    local right_col = math.floor(check_px + entity.width - C.EPS)
    local top_row = math.floor(check_py + C.EPS)
    local bottom_row = math.floor(check_py + entity.height - C.EPS)

    -- Check for solid blocks
    for col = left_col, right_col do
        for row = top_row, bottom_row do
            if world:is_solid(entity.z, col, row) then
                return false
            end
        end
    end

    -- Check for other drops
    if world.entities then
        for _, other in ipairs(world.entities) do
            if other ~= entity and other.proto and other.z == entity.z then
                local overlap_x = not (check_px + entity.width <= other.px or check_px >= other.px + other.width)
                local overlap_y = not (check_py + entity.height <= other.py or check_py >= other.py + other.height)

                if overlap_x and overlap_y then
                    return false
                end
            end
        end
    end

    return true
end

-- Apply sand-like spreading physics to drops
function Physics.apply_spreading(entity, world, dt)
    -- Only apply to drops that are grounded and not being held
    if not entity.proto or entity.being_held then return end
    if entity.vy ~= 0 then return end  -- Not grounded

    -- Check if we have support on bottom-left or bottom-right
    local has_left_support = has_support_below(entity, world, entity.px - 0.5)
    local has_right_support = has_support_below(entity, world, entity.px + 0.5)
    local has_center_support = has_support_below(entity, world, entity.px)

    -- If centered and has support, no spreading needed
    if has_center_support and has_left_support and has_right_support then
        return
    end

    -- Try to roll off if no support on one side
    local spread_speed = 0.5 * dt  -- Slow spreading

    -- Prefer rolling to the side with no support
    if not has_left_support and has_right_support then
        -- Try moving left
        local new_px = entity.px - spread_speed
        local new_py = entity.py
        if is_position_free(entity, new_px, new_py, world) then
            entity.px = new_px
            return
        end
    elseif not has_right_support and has_left_support then
        -- Try moving right
        local new_px = entity.px + spread_speed
        local new_py = entity.py
        if is_position_free(entity, new_px, new_py, world) then
            entity.px = new_px
            return
        end
    elseif not has_center_support then
        -- No center support, try both directions (random choice)
        local try_left_first = math.random() < 0.5

        if try_left_first then
            -- Try left first
            local new_px = entity.px - spread_speed
            local new_py = entity.py
            if is_position_free(entity, new_px, new_py, world) then
                entity.px = new_px
                return
            end
            -- Try right as fallback
            new_px = entity.px + spread_speed
            if is_position_free(entity, new_px, new_py, world) then
                entity.px = new_px
                return
            end
        else
            -- Try right first
            local new_px = entity.px + spread_speed
            local new_py = entity.py
            if is_position_free(entity, new_px, new_py, world) then
                entity.px = new_px
                return
            end
            -- Try left as fallback
            new_px = entity.px - spread_speed
            if is_position_free(entity, new_px, new_py, world) then
                entity.px = new_px
                return
            end
        end
    end
end

function Physics.move(entity, dx, dy, world)
    assert(entity)
    if dx ~= 0 then
        local desired_px = entity.px + dx
        if desired_px > entity.px then
            move_right(entity, desired_px, world)
        else
            move_left(entity, desired_px, world)
        end
    end
    if dy ~= 0 then
        local desired_py = entity.py + dy
        if desired_py > entity.py then
            move_down(entity, desired_py, world)
        else
            move_up(entity, desired_py, world)
        end
    end
end

return Physics
