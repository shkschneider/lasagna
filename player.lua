-- Player entity and controls

local world = require("world")
local inventory = require("inventory")

local player = {}

function player.new(x, y, layer)
    print(string.format("Creating player at (%.1f, %.1f, %d)", x, y, layer))
    return {
        x = x or 0,
        y = y or 0,
        vx = 0,
        vy = 0,
        layer = layer or 0,
        width = 8,  -- 1 block wide (8 pixels)
        height = 16, -- 2 blocks tall (16 pixels)
        on_ground = false,
        inventory = inventory.new(),
        omnitool_tier = 0, -- Starting tier
        mining_progress = 0,
        mining_target = nil, -- {layer, col, row}
        _debug_frame = 0,  -- Debug frame counter
    }
end

function player.update(p, dt, w)
    local MOVE_SPEED = 150
    local JUMP_FORCE = 300
    local GRAVITY = 800

    -- Debug first few frames
    if p._debug_frame < 5 then
        print(string.format("Frame %d: player pos=(%.1f, %.1f), vy=%.1f, on_ground=%s", 
            p._debug_frame, p.x, p.y, p.vy, tostring(p.on_ground)))
        p._debug_frame = p._debug_frame + 1
    end

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

    -- AABB collision detection helper
    local function check_collision(x, y, width, height, layer)
        -- Check all blocks that the player AABB overlaps
        local left = x - width / 2
        local right = x + width / 2
        local top = y - height / 2
        local bottom = y + height / 2
        
        local start_col = math.floor(left / world.BLOCK_SIZE)
        local end_col = math.floor(right / world.BLOCK_SIZE)
        local start_row = math.floor(top / world.BLOCK_SIZE)
        local end_row = math.floor(bottom / world.BLOCK_SIZE)
        
        for col = start_col, end_col do
            for row = start_row, end_row do
                local proto = world.get_block_proto(w, layer, col, row)
                if proto and proto.solid then
                    return true, col, row
                end
            end
        end
        return false
    end

    -- Apply horizontal movement with collision
    local new_x = p.x + p.vx * dt
    if not check_collision(new_x, p.y, p.width, p.height, p.layer) then
        p.x = new_x
    else
        -- Snap to edge of blocking tile
        if p.vx > 0 then
            -- Moving right, snap to left edge of blocking tile
            local col = math.floor((new_x + p.width / 2) / world.BLOCK_SIZE)
            p.x = col * world.BLOCK_SIZE - p.width / 2
        elseif p.vx < 0 then
            -- Moving left, snap to right edge of blocking tile
            local col = math.floor((new_x - p.width / 2) / world.BLOCK_SIZE)
            p.x = (col + 1) * world.BLOCK_SIZE + p.width / 2
        end
        p.vx = 0
    end

    -- Apply vertical movement with collision
    local new_y = p.y + p.vy * dt
    p.on_ground = false
    
    local collision, col, row = check_collision(p.x, new_y, p.width, p.height, p.layer)
    if not collision then
        p.y = new_y
    else
        if p.vy > 0 then
            -- Moving down, snap to top of blocking tile
            local row = math.floor((new_y + p.height / 2) / world.BLOCK_SIZE)
            p.y = row * world.BLOCK_SIZE - p.height / 2
            p.on_ground = true
            print(string.format("Collision detected: player y=%.1f snapped to %.1f (row %d)", new_y, p.y, row))
        elseif p.vy < 0 then
            -- Moving up, snap to bottom of blocking tile
            local row = math.floor((new_y - p.height / 2) / world.BLOCK_SIZE)
            p.y = (row + 1) * world.BLOCK_SIZE + p.height / 2
        end
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
