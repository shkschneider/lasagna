-- Drop System
-- Manages drop entities (items on ground)

local Object = require "core.object"
local Position = require "components.position"
local Velocity = require "components.velocity"
local Physics = require "components.physics"
local Drop = require "components.drop"
local Registry = require "registries"

local MERGING_ENABLED = false

local DropSystem = Object.new {
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
        physics = Physics.new(400, 0.8),  -- gravity: 400, friction: 0.8 (more friction for drops)
        drop = Drop.new(block_id, count, 300, 0.5),
    }
    table.insert(self.entities, entity)
    return entity
end

function DropSystem.update(self, dt)
    local PICKUP_RANGE = BLOCK_SIZE
    local MERGE_RANGE = BLOCK_SIZE
    local player_x, player_y, player_z = G.player:get_position()

    for i = #self.entities, 1, -1 do
        local ent = self.entities[i]

        -- Physics
        ent.velocity.vy = ent.velocity.vy + ent.physics.gravity * dt
        ent.position.x = ent.position.x + ent.velocity.vx * dt
        ent.position.y = ent.position.y + ent.velocity.vy * dt

        -- Check collision with ground
        -- Drops are 1/2 block size, so check at their bottom edge (1/4 block offset)
        local drop_height = BLOCK_SIZE / 2
        local col, row = G.world:world_to_block(
            ent.position.x,
            ent.position.y + drop_height / 2
        )
        local block_def = G.world:get_block_def(ent.position.z, col, row)

        local on_ground = false
        if block_def and block_def.solid then
            ent.velocity.vy = 0
            -- Position drop so its bottom edge rests on top of the block
            ent.position.y = row * BLOCK_SIZE - drop_height / 2
            on_ground = true
        end

        -- Apply friction only when on ground
        if on_ground then
            ent.velocity.vx = ent.velocity.vx * ent.physics.friction
        end

        -- Merge with nearby drops of the same type (performance optimization)
        -- Only merge when on ground and pickup delay is over
        if MERGING_ENABLED and on_ground and ent.drop.pickup_delay <= 0 then
            for j = i - 1, 1, -1 do
                local other = self.entities[j]

                -- Check if same block type and on same layer
                if other.drop.block_id == ent.drop.block_id and other.position.z == ent.position.z then
                    local dx = other.position.x - ent.position.x
                    local dy = other.position.y - ent.position.y
                    local dist = math.sqrt(dx * dx + dy * dy)

                    -- Merge if within range and other is also on ground with no pickup delay
                    if dist < MERGE_RANGE and other.drop.pickup_delay <= 0 then
                        -- Check if other drop is also on ground
                        local other_col, other_row = G.world:world_to_block(
                            other.position.x,
                            other.position.y + drop_height / 2
                        )
                        local other_block = G.world:get_block_def(other.position.z, other_col, other_row)

                        if other_block and other_block.solid then
                            -- Merge counts and remove the other drop
                            ent.drop.count = ent.drop.count + other.drop.count
                            table.remove(self.entities, j)
                            -- Adjust index since we removed an element before current
                            i = i - 1
                        end
                    end
                end
            end
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
                if G.player:add_to_inventory(ent.drop.block_id, ent.drop.count) then
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
    local camera_x, camera_y = G.camera:get_offset()

    for _, ent in ipairs(self.entities) do
        local proto = Registry.Blocks:get(ent.drop.block_id)
        if proto then
            -- Drop is 1/2 width and 1/2 height (1/4 surface area)
            local width = BLOCK_SIZE / 2
            local height = BLOCK_SIZE / 2
            local x = ent.position.x - camera_x - width / 2
            local y = ent.position.y - camera_y - height / 2

            -- Draw the colored block
            love.graphics.setColor(proto.color)
            love.graphics.rectangle("fill", x, y, width, height)

            if MERGING_ENABLED and ent.drop.count > 1 then
                -- Draw 1px gold border
                love.graphics.setColor(1, 0.8, 0, 1)
                love.graphics.rectangle("line", x, y, width, height)
            else
                -- Draw 1px white border
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.rectangle("line", x, y, width, height)
            end
        end
    end

    -- Reset color to white for subsequent rendering
    love.graphics.setColor(1, 1, 1, 1)
end

return DropSystem
