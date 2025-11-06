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

function Physics.move(entity, dx, dy, world)
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
