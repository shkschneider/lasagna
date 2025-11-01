local C = require("constants")

local Movements = {}

local function move_right(entity, desired_px, world)
    -- No horizontal bounds clamping for infinite world
    local right_now = math.floor(entity.px + entity.width - 1e-6)
    local right_desired = math.floor(desired_px + entity.width - 1e-6)
    local top_row = math.floor(entity.py + 1e-6)
    local bottom_row = math.floor(entity.py + entity.height - 1e-6)
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
        local left_col = math.floor(desired_px + 1e-6)
        local right_col = math.floor(desired_px + entity.width - 1e-6)
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
    local left_now = math.floor(entity.px + 1e-6)
    local left_desired = math.floor(desired_px + 1e-6)
    local top_row = math.floor(entity.py + 1e-6)
    local bottom_row = math.floor(entity.py + entity.height - 1e-6)
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
        local left_col = math.floor(desired_px + 1e-6)
        local right_col = math.floor(desired_px + entity.width - 1e-6)
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
    local top_row = math.floor(entity.py + 1e-6)
    local bottom_now = math.floor(entity.py + entity.height - 1e-6)
    local bottom_desired = math.floor(desired_py + entity.height - 1e-6)
    local left_col = math.floor(entity.px + 1e-6)
    local right_col = math.floor(entity.px + entity.width - 1e-6)
    local blocked = false
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
    if blocked then
        entity.vy = 0
        entity.on_ground = true
    else
        local top_row2 = math.floor(desired_py + 1e-6)
        local bottom_row2 = math.floor(desired_py + entity.height - 1e-6)
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
        if blocked then
            entity.vy = 0
            entity.on_ground = true
        else
            entity.on_ground = false
        end
    end
    entity.py = desired_py
end

local function move_up(entity, desired_py, world)
    if desired_py < 1 then desired_py = 1 end
    if desired_py > math.max(1, C.WORLD_HEIGHT - entity.height + 1) then desired_py = math.max(1, C.WORLD_HEIGHT - entity.height + 1) end
    local top_now = math.floor(entity.py + 1e-6)
    local top_desired = math.floor(desired_py + 1e-6)
    local left_col = math.floor(entity.px + 1e-6)
    local right_col = math.floor(entity.px + entity.width - 1e-6)
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

function Movements.move(entity, dx, dy, world)
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

return Movements
