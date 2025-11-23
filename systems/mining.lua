-- Mining System
-- Handles block mining with progressive delay and visual feedback

local Systems = require "systems"
local Registry = require "registries"

local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

local MiningSystem = {
    id = "mining",
    priority = 60,
    -- Mining state
    mining_active = false,
    mining_block = nil, -- {z, col, row, progress, delay}
}

-- Visual constants for mining overlay
local MINING_OVERLAY_COLOR = {0, 0, 0, 0.5} -- Black with 80% opacity

-- Base blocks that mine quickly
local BASE_BLOCKS = {
    ["Dirt"] = true,
    ["Grass"] = true,
    ["Sand"] = true,
    ["Wood"] = true,
}

-- Calculate mining delay for a block based on its tier and name
function MiningSystem.get_mining_delay(self, omnitool_tier, proto)
    local BASE = 0.25 / omnitool_tier

    if not proto or not proto.solid then
        -- Non-solid blocks (like air) should not be mined
        return 0
    end

    return (proto.tier + 1) * BASE
end

function MiningSystem.load(self)
    self.mining_active = false
    self.mining_block = nil
end

function MiningSystem.update(self, dt)
    -- Update mining progress if actively mining
    if self.mining_active and self.mining_block then
        local world = Systems.get("world")
        local player = Systems.get("player")
        local player_x, player_y, player_z = player:get_position()

        -- Check if still holding mouse button
        if not love.mouse.isDown(1) then
            self:cancel_mining()
            return
        end

        -- Check if player changed layers
        if player_z ~= self.mining_block.z then
            self:cancel_mining()
            return
        end

        -- Check if block still exists and is the same
        local block_id = world:get_block_id(self.mining_block.z, self.mining_block.col, self.mining_block.row)
        local proto = Registry.Blocks:get(block_id)
        -- Cancel if block no longer exists or changed
        if not proto or block_id ~= self.mining_block.block_id or proto.id ~= self.mining_block.proto.id then
            self:cancel_mining()
            return
        end

        -- Update progress
        self.mining_block.progress = self.mining_block.progress + dt

        -- Check if mining complete
        if self.mining_block.progress >= self.mining_block.delay then
            self:complete_mining()
        end
    end
end

function MiningSystem.mousepressed(self, x, y, button)
    if button ~= 1 then
        return
    end

    -- Get systems
    local world = Systems.get("world")
    local player = Systems.get("player")
    local camera = Systems.get("camera")

    local camera_x, camera_y = camera:get_offset()
    local world_x = x + camera_x
    local world_y = y + camera_y

    local col, row = world:world_to_block(world_x, world_y)

    -- Start mining block
    self:start_mining(col, row, world, player)
end

function MiningSystem.mousereleased(self, x, y, button)
    if button == 1 then
        self:cancel_mining()
    end
end

function MiningSystem.mousemoved(self, x, y, dx, dy)
    -- If actively mining, check if cursor moved to a new block
    if self.mining_active and self.mining_block then
        local world = Systems.get("world")
        local player = Systems.get("player")
        local camera = Systems.get("camera")
        
        local camera_x, camera_y = camera:get_offset()
        local world_x = x + camera_x
        local world_y = y + camera_y
        
        local col, row = world:world_to_block(world_x, world_y)
        
        -- Check if cursor moved to a different block
        if col ~= self.mining_block.col or row ~= self.mining_block.row then
            -- Start mining the new block
            self:start_mining(col, row, world, player)
        end
    end
end

function MiningSystem.start_mining(self, col, row, world, player)
    local player_x, player_y, player_z = player:get_position()
    local block_id = world:get_block_id(player_z, col, row)
    local proto = Registry.Blocks:get(block_id)

    if not proto or not proto.solid then
        return
    end

    -- Check if player has omnitool equipped
    local inv = player.components.inventory
    local selected_slot = inv.slots[inv.selected_slot]
    if not selected_slot or selected_slot.item_id ~= ITEMS.OMNITOOL then
        return -- Can only mine with omnitool equipped
    end

    -- Check tier requirement
    local player_tier = player:get_omnitool_tier()
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
    self.mining_active = true
    self.mining_block = {
        z = player_z,
        col = col,
        row = row,
        block_id = block_id,
        proto = proto,
        progress = 0,
        delay = delay,
    }
end

function MiningSystem.cancel_mining(self)
    self.mining_active = false
    self.mining_block = nil
end

function MiningSystem.complete_mining(self)
    if not self.mining_block then
        return
    end

    local world = Systems.get("world")
    local z = self.mining_block.z
    local col = self.mining_block.col
    local row = self.mining_block.row
    local proto = self.mining_block.proto

    -- Remove block
    world:set_block(z, col, row, BLOCKS.AIR)

    -- Spawn drop
    if proto.drops then
        local drop = Systems.get("drop")
        if drop then
            local drop_id, drop_count = proto.drops()
            if drop_id then
                local wx, wy = world:block_to_world(col, row)
                drop.create_drop(drop,
                    wx + BLOCK_SIZE / 2,
                    wy + BLOCK_SIZE / 2,
                    z,
                    drop_id,
                    drop_count
                )
            end
        end
    end

    -- Check if mouse button is still held down
    if love.mouse.isDown(1) then
        -- Get current cursor position and try to start mining the block under cursor
        local mouse_x, mouse_y = love.mouse.getPosition()
        local player = Systems.get("player")
        local camera = Systems.get("camera")
        
        local camera_x, camera_y = camera:get_offset()
        local world_x = mouse_x + camera_x
        local world_y = mouse_y + camera_y
        
        local new_col, new_row = world:world_to_block(world_x, world_y)
        
        -- Start mining the new block under cursor (this will reset the state)
        self:start_mining(new_col, new_row, world, player)
    else
        -- Reset mining state
        self:cancel_mining()
    end
end

-- Draw mining progress overlay
function MiningSystem.draw(self)
    if not self.mining_active or not self.mining_block then
        return
    end

    local camera = Systems.get("camera")
    local world = Systems.get("world")

    local camera_x, camera_y = camera:get_offset()
    local wx, wy = world:block_to_world(self.mining_block.col, self.mining_block.row)

    -- Convert to screen coordinates
    local screen_x = wx - camera_x
    local screen_y = wy - camera_y

    -- Calculate progress ratio
    local progress = math.min(self.mining_block.progress / self.mining_block.delay, 1.0)

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

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return MiningSystem
