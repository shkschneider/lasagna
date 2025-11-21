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
        width = 16,
        height = 32,
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

    -- Apply velocity
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt

    -- Collision detection
    local col, row = world.world_to_block(p.x, p.y + p.height / 2)
    local block_proto = world.get_block_proto(w, p.layer, col, row)

    -- Ground collision
    p.on_ground = false
    if block_proto and block_proto.solid then
        if p.vy > 0 then
            p.y = row * world.BLOCK_SIZE - p.height / 2
            p.vy = 0
            p.on_ground = true
        end
    end

    -- Check ceiling collision
    local top_col, top_row = world.world_to_block(p.x, p.y - p.height / 2)
    local top_block = world.get_block_proto(w, p.layer, top_col, top_row)
    if top_block and top_block.solid and p.vy < 0 then
        p.y = (top_row + 1) * world.BLOCK_SIZE + p.height / 2
        p.vy = 0
    end

    -- Prevent falling through bottom
    if p.y > world.HEIGHT * world.BLOCK_SIZE then
        p.y = world.HEIGHT * world.BLOCK_SIZE
        p.vy = 0
        p.on_ground = true
    end
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
