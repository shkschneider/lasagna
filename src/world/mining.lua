local Love = require "core.love"
local Object = require "core.object"
local Registry = require "src.registries"
local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

-- Visual constants for mining overlay
local MINING_OVERLAY_COLOR = {0, 0, 0, 0.5} -- Black with 80% opacity

local Mining = Object {
    id = "mining",
    priority = 60,
    -- Mining state
    target = nil, -- {z, col, row, progress, delay}
    mouse_held = false, -- Track if left mouse button is being held
}

-- Calculate mining delay for a block based on its tier and name
function Mining.get_mining_delay(self, omnitool_tier, proto)
    local BASE = 0.25 / omnitool_tier
    if not proto or not proto.solid then
        return 0
    end
    return (proto.tier + 1) * BASE
end

function Mining.load(self)
    self.target = nil
    self.mouse_held = false
    Love.load(self)
end

function Mining.update(self, dt)
    local slot = G.player.hotbar:get_selected()
    -- Cancel mining if mouse is not held, or wrong tool selected
    if not self.mouse_held or not slot or slot.item_id ~= ITEMS.OMNITOOL then
        self:cancel_mining()
        return
    end
    -- Update mining progress if actively mining
    local player_x, player_y, player_z = G.player:get_position()
    if not self.target then
        -- Start mining block
        local camera_x, camera_y = G.camera:get_offset()
        local mx, my = love.mouse.getPosition()
        local world_x = mx + camera_x
        local world_y = my + camera_y
        local col, row = G.world:world_to_block(world_x, world_y)
        self:start_mining(col, row)
    else
        -- Check if player changed layers
        if player_z ~= self.target.z then
            self:cancel_mining()
            return
        end
        -- Continue mining
        self.target.progress = self.target.progress + dt
        -- Check if mining complete
        if self.target.progress >= self.target.delay then
            self:complete_mining()
        end
    end
    Love.update(self, dt)
end

function Mining.start_mining(self, col, row)
    local player_x, player_y, player_z = G.player:get_position()
    local block_id = G.world:get_block_id(player_z, col, row)
    local proto = Registry.Blocks:get(block_id)

    if not proto or not proto.solid then
        return
    end

    -- DONT Check if player has omnitool equipped

    -- Check tier requirement
    local player_tier = G.player:get_omnitool_tier()
    if proto.tier > player_tier then
        return -- Can't mine this yet
    end

    -- Get mining delay for this block
    local delay = self:get_mining_delay(player_tier, proto)

    -- Validate delay (should be positive for solid, minable blocks)
    -- Non-solid blocks return 0 and are already filtered out above
    if delay <= 0 then
        return
    end

    -- Start mining
    self.target = {
        z = player_z,
        col = col,
        row = row,
        block_id = block_id,
        proto = proto,
        progress = 0,
        delay = delay,
    }
end

function Mining.cancel_mining(self)
    self.target = nil
end

function Mining.complete_mining(self)
    if not self.target then
        return
    end

    local z = self.target.z
    local col = self.target.col
    local row = self.target.row
    local proto = self.target.proto

    -- Remove block
    G.world:set_block(z, col, row, BLOCKS.AIR)
    
    -- Remove machine entity if this was a machine block
    self:remove_machine_entity(col, row, z, self.target.block_id)

    -- Spawn drop
    if proto.drops then
        local drop_id, drop_count = proto.drops()
        if drop_id then
            local ItemDrop = require "src.entities.itemdrop"
            local wx, wy = G.world:block_to_world(col, row)
            local drop = ItemDrop.new(
                wx + BLOCK_SIZE / 2,
                wy + BLOCK_SIZE / 2,
                z,
                drop_id,
                drop_count
            )
            G.entities:add(drop)
        end
    end

    -- Reset mining state
    self:cancel_mining()
end

function Mining.remove_machine_entity(self, col, row, layer, block_id)
    -- Check if this block was a machine type
    if block_id == BLOCKS.WORKBENCH then
        -- Find and remove the machine entity at this position
        local machines = G.entities:getByType("machine")
        local wx, wy = G.world:block_to_world(col, row)
        
        for _, machine in ipairs(machines) do
            -- Check if machine is at this position (within a small tolerance)
            if machine.position.z == layer and
               math.abs(machine.position.x - wx) < 1 and
               math.abs(machine.position.y - wy) < 1 then
                machine.dead = true
                break
            end
        end
    end
end

-- Draw mining progress overlay
function Mining.draw(self)
    if not self.target then
        return
    end

    local camera_x, camera_y = G.camera:get_offset()
    local wx, wy = G.world:block_to_world(self.target.col, self.target.row)

    -- Convert to screen coordinates
    local screen_x = wx - camera_x
    local screen_y = wy - camera_y

    -- Calculate progress ratio
    local progress = math.min(self.target.progress / self.target.delay, 1.0)

    -- Draw black square that grows from center
    local max_size = BLOCK_SIZE
    local current_size = max_size * progress
    local offset = (max_size - current_size) / 2

    love.graphics.setColor(MINING_OVERLAY_COLOR)
    love.graphics.rectangle("fill",
        screen_x + offset,
        screen_y + offset,
        current_size,
        current_size
    )

    Love.draw(self)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle mouse pressed event to start tracking mouse hold
function Mining.mousepressed(self, x, y, button)
    if button == 1 then
        self.mouse_held = true
    end
    Love.mousepressed(self, x, y, button)
end

-- Handle mouse released event to stop mining
function Mining.mousereleased(self, x, y, button)
    if button == 1 then
        self.mouse_held = false
        -- Mining will be cancelled in the next update() call
    end
    Love.mousereleased(self, x, y, button)
end

return Mining
