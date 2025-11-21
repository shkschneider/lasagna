-- Player entity and controls

local world = require("world")
local inventory = require("inventory")

local player = {}

function player.new(x, y, layer)
    return {
        x = x or 0,
        y = y or 0,
        vx = 0,
        vy = 0,
        layer = layer or 0,
        width = 32,  -- 1 block wide
        height = 64, -- 2 blocks tall
        on_ground = false,
        inventory = inventory.new(),
        omnitool_tier = 0, -- Starting tier
        mining_progress = 0,
        mining_target = nil, -- {layer, col, row}
    }
end

function player.update(p, dt, w)
    local MOVE_SPEED = 150
    local JUMP_FORCE = 300
    local GRAVITY = 800

    -- Horizontal movement
    p.vx = 0
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        p.vx = -MOVE_SPEED
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        p.vx = MOVE_SPEED
    end

    -- Vertical movement (gravity)
    p.vy = p.vy + GRAVITY * dt

    -- Jump
    if (love.keyboard.isDown("w") or love.keyboard.isDown("space") or love.keyboard.isDown("up")) and p.on_ground then
        p.vy = -JUMP_FORCE
        p.on_ground = false
    end

    -- Apply horizontal velocity with collision
    local new_x = p.x + p.vx * dt
    if not player.check_collision(p, w, new_x, p.y) then
        p.x = new_x
    end

    -- Apply vertical velocity with collision
    local new_y = p.y + p.vy * dt
    
    -- Check ground collision (bottom of player)
    p.on_ground = false
    local bottom_y = new_y + p.height / 2
    local left_col = math.floor((p.x - p.width / 2) / world.BLOCK_SIZE)
    local right_col = math.floor((p.x + p.width / 2 - 1) / world.BLOCK_SIZE)
    local bottom_row = math.floor(bottom_y / world.BLOCK_SIZE)
    
    -- Check all blocks at the bottom of the player
    for col = left_col, right_col do
        local block_proto = world.get_block_proto(w, p.layer, col, bottom_row)
        if block_proto and block_proto.solid and p.vy >= 0 then
            -- Collision with ground
            p.y = bottom_row * world.BLOCK_SIZE - p.height / 2
            p.vy = 0
            p.on_ground = true
            new_y = p.y
            break
        end
    end
    
    -- Check ceiling collision (top of player)
    local top_y = new_y - p.height / 2
    local top_row = math.floor(top_y / world.BLOCK_SIZE)
    
    for col = left_col, right_col do
        local block_proto = world.get_block_proto(w, p.layer, col, top_row)
        if block_proto and block_proto.solid and p.vy < 0 then
            -- Collision with ceiling
            p.y = (top_row + 1) * world.BLOCK_SIZE + p.height / 2
            p.vy = 0
            new_y = p.y
            break
        end
    end
    
    if not p.on_ground then
        p.y = new_y
    end

    -- Prevent falling through bottom
    if p.y > world.HEIGHT * world.BLOCK_SIZE then
        p.y = world.HEIGHT * world.BLOCK_SIZE
        p.vy = 0
        p.on_ground = true
    end
end

-- Check if player collides with solid blocks at the given position
function player.check_collision(p, w, x, y, layer)
    layer = layer or p.layer
    local left = x - p.width / 2
    local right = x + p.width / 2 - 1
    local top = y - p.height / 2
    local bottom = y + p.height / 2 - 1
    
    local left_col = math.floor(left / world.BLOCK_SIZE)
    local right_col = math.floor(right / world.BLOCK_SIZE)
    local top_row = math.floor(top / world.BLOCK_SIZE)
    local bottom_row = math.floor(bottom / world.BLOCK_SIZE)
    
    for col = left_col, right_col do
        for row = top_row, bottom_row do
            local block_proto = world.get_block_proto(w, layer, col, row)
            if block_proto and block_proto.solid then
                return true
            end
        end
    end
    
    return false
end

function player.draw(p, camera_x, camera_y)
    love.graphics.setColor(1, 1, 1, 1) -- Blue player
    love.graphics.rectangle("fill",
        p.x - camera_x - p.width / 2,
        p.y - camera_y - p.height / 2,
        p.width,
        p.height)
end

return player
