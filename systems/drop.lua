-- Drop System
-- Manages drop entities (items on ground)

require "lib"

local Systems = require "systems"
local Position = require "components.position"
local Velocity = require "components.velocity"
local Physics = require "components.physics"
local Drop = require "components.drop"
local Registry = require "registries"

local DropSystem = {
    id = "drop",
    priority = 70,
    entities = {},
}

function DropSystem.load(self)
    self.entities = {}
end

function DropSystem.create_drop(self, x, y, layer, block_id, count)
    local entity = {
        id = uuid(),
        position = Position.new(x, y, layer),
        velocity = Velocity.new((math.random() - 0.5) * 50, -50),
        physics = Physics.new(false, 400, 0.95),
        drop = Drop.new(block_id, count, 300, 0.5),
    }

    table.insert(self.entities, entity)

    return entity
end

function DropSystem.update(self, dt)
    -- Get systems from G
    local world = Systems.get("world")
    local player = Systems.get("player")

    local PICKUP_RANGE = world.BLOCK_SIZE
    local player_x, player_y, player_z = player:get_position()

    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]

        -- Physics
        ent.velocity.vy = ent.velocity.vy + ent.physics.gravity * dt
        ent.position.x = ent.position.x + ent.velocity.vx * dt
        ent.position.y = ent.position.y + ent.velocity.vy * dt

        -- Friction
        ent.velocity.vx = ent.velocity.vx * ent.physics.friction

        -- Check collision with ground
        local col, row = world.world_to_block(world,
            ent.position.x,
            ent.position.y + world.BLOCK_SIZE / 2
        )
        local block_def = world:get_block_def(ent.position.z, col, row)

        if block_def and block_def.solid then
            ent.velocity.vy = 0
            ent.position.y = row * world.BLOCK_SIZE - world.BLOCK_SIZE / 2
        end

        -- Decrease pickup delay
        if ent.drop.pickup_delay > 0 then
            ent.drop.pickup_delay = ent.drop.pickup_delay - dt
        end

        -- Check pickup by player
        if ent.drop.pickup_delay <= 0 and ent.position.z == player_z then
            local dx = ent.position.x - player_x
            local dy = ent.position.y - player_y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < PICKUP_RANGE then
                -- Try to add to player inventory
                if player:add_to_inventory(ent.drop.block_id, ent.drop.count) then
                    -- Successfully picked up
                    table.remove(self.entities, i)
                end
            end
        end

        -- Lifetime
        ent.drop.lifetime = ent.drop.lifetime - dt
        if ent.drop.lifetime <= 0 then
            table.remove(self.entities, i)
        end
    end
end

function DropSystem.draw(self)
    -- Get systems from G
    local world = Systems.get("world")
    local camera = Systems.get("camera")

    local camera_x, camera_y = camera:get_offset()

    for _, ent in ipairs(self.entities) do
        local proto = Registry.Blocks:get(ent.drop.block_id)
        if proto then
            -- Drop is 1/2 width and 1/2 height (1/4 surface area)
            local width = world.BLOCK_SIZE / 2
            local height = world.BLOCK_SIZE / 2
            local x = ent.position.x - camera_x - width / 2
            local y = ent.position.y - camera_y - height / 2
            
            -- Draw the colored block
            love.graphics.setColor(proto.color)
            love.graphics.rectangle("fill", x, y, width, height)
            
            -- Draw 1px white border
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", x, y, width, height)
        end
    end
end

return DropSystem
