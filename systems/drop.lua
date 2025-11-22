-- Drop System
-- Manages drop entities (items on ground)

local Position = require("components.position")
local Velocity = require("components.velocity")
local Physics = require("components.physics")
local Drop = require("components.drop")
local Blocks = require("core.blocks")

local DropSystem = {
    id = "drop",
    priority = 70,
    entities = {},
    next_id = 1,
}

function DropSystem.load(self, world_system, player_system)
    self.world_system = world_system
    self.player_system = player_system
    self.entities = {}
    self.next_id = 1
end

function DropSystem.create_drop(self, x, y, layer, block_id, count)
    local entity = {
        id = self.next_id,
        position = Position.new(x, y, layer),
        velocity = Velocity.new((math.random() - 0.5) * 50, -50),
        physics = Physics.new(false, 400, 0.95),
        drop = Drop.new(block_id, count, 300, 0.5),
    }

    self.next_id = self.next_id + 1
    table.insert(self.entities, entity)

    return entity
end

function DropSystem.update(self, dt)
    local PICKUP_RANGE = self.world_system.BLOCK_SIZE
    local player_x, player_y, player_layer = self.player_system:get_position()

    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]

        -- Physics
        ent.velocity.vy = ent.velocity.vy + ent.physics.gravity * dt
        ent.position.x = ent.position.x + ent.velocity.vx * dt
        ent.position.y = ent.position.y + ent.velocity.vy * dt

        -- Friction
        ent.velocity.vx = ent.velocity.vx * ent.physics.friction

        -- Check collision with ground
        local col, row = self.world_system:world_to_block(
            ent.position.x,
            ent.position.y + self.world_system.BLOCK_SIZE / 2
        )
        local block_proto = self.world_system:get_block_proto(ent.position.layer, col, row)

        if block_proto and block_proto.solid then
            ent.velocity.vy = 0
            ent.position.y = row * self.world_system.BLOCK_SIZE - self.world_system.BLOCK_SIZE / 2
        end

        -- Decrease pickup delay
        if ent.drop.pickup_delay > 0 then
            ent.drop.pickup_delay = ent.drop.pickup_delay - dt
        end

        -- Check pickup by player
        if ent.drop.pickup_delay <= 0 and ent.position.layer == player_layer then
            local dx = ent.position.x - player_x
            local dy = ent.position.y - player_y
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist < PICKUP_RANGE then
                -- Try to add to player inventory
                if self.player_system:add_to_inventory(ent.drop.block_id, ent.drop.count) then
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

function DropSystem.draw(self, camera_x, camera_y)
    for _, ent in ipairs(self.entities) do
        local proto = blocks.get_proto(ent.drop.block_id)
        if proto then
            local size = self.world_system.BLOCK_SIZE / 2
            love.graphics.setColor(proto.color)
            love.graphics.rectangle("fill",
                ent.position.x - camera_x - size / 2,
                ent.position.y - camera_y - size / 2,
                size,
                size)
        end
    end
end

return DropSystem
