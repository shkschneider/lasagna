-- Entity system
-- Handles drops, physics, and entity lifecycle

local blocks = require("blocks")
local world = require("world")
local inventory = require("inventory")

local entities = {}

-- Constants
local DROP_LIFETIME = 300 -- Seconds before despawn
local DROP_PICKUP_DELAY = 0.5 -- Delay before can be picked up

-- Entity list
function entities.new()
    return {
        list = {},
        next_id = 1,
    }
end

-- Drop entity component
function entities.create_drop(ent_system, x, y, layer, block_id, count)
    local drop = {
        id = ent_system.next_id,
        type = "drop",
        x = x,
        y = y,
        vx = (math.random() - 0.5) * 50, -- Random horizontal velocity
        vy = -50, -- Initial upward velocity
        layer = layer,
        block_id = block_id,
        count = count,
        lifetime = DROP_LIFETIME,
        pickup_delay = DROP_PICKUP_DELAY,
    }
    
    ent_system.next_id = ent_system.next_id + 1
    table.insert(ent_system.list, drop)
    
    return drop
end

-- Update all entities
function entities.update(ent_system, dt, w, player)
    local GRAVITY = 400
    local FRICTION = 0.95
    local PICKUP_RANGE = 32
    
    for i = #ent_system.list, 1, -1 do
        local ent = ent_system.list[i]
        
        if ent.type == "drop" then
            -- Physics
            ent.vy = ent.vy + GRAVITY * dt
            ent.x = ent.x + ent.vx * dt
            ent.y = ent.y + ent.vy * dt
            
            -- Friction
            ent.vx = ent.vx * FRICTION
            
            -- Check collision with ground
            local col, row = world.world_to_block(ent.x, ent.y + 8)
            local block_proto = world.get_block_proto(w, ent.layer, col, row)
            
            if block_proto and block_proto.solid then
                ent.vy = 0
                ent.y = row * world.BLOCK_SIZE - 8
            end
            
            -- Decrease pickup delay
            if ent.pickup_delay > 0 then
                ent.pickup_delay = ent.pickup_delay - dt
            end
            
            -- Check pickup by player
            if ent.pickup_delay <= 0 and ent.layer == player.layer then
                local dx = ent.x - player.x
                local dy = ent.y - player.y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                if dist < PICKUP_RANGE then
                    -- Try to add to player inventory
                    if player.inventory then
                        if inventory.add(player.inventory, ent.block_id, ent.count) then
                            -- Successfully picked up
                            table.remove(ent_system.list, i)
                        end
                    end
                end
            end
            
            -- Lifetime
            ent.lifetime = ent.lifetime - dt
            if ent.lifetime <= 0 then
                table.remove(ent_system.list, i)
            end
        end
    end
end

-- Draw all entities
function entities.draw(ent_system, camera_x, camera_y)
    for _, ent in ipairs(ent_system.list) do
        if ent.type == "drop" then
            local proto = blocks.get_proto(ent.block_id)
            if proto then
                love.graphics.setColor(proto.color)
                -- Drops are half the width and height of blocks (16x16)
                love.graphics.rectangle("fill", 
                    ent.x - camera_x - 8, 
                    ent.y - camera_y - 8, 
                    16, 16)
            end
        end
    end
end

return entities
