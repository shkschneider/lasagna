-- Mining System
-- Handles block mining with progressive delay and visual feedback

local Object = require "core.object"
local Systems = require "systems"
local Registry = require "registries"

local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

local MiningSystem = Object.new {
    id = "mining",
    priority = 60,
    -- Mining state
    target = nil, -- {z, col, row, progress, delay}
}

-- Visual constants for mining overlay
local MINING_OVERLAY_COLOR = {0, 0, 0, 0.5} -- Black with 80% opacity

-- Calculate mining delay for a block based on its tier and name
function MiningSystem.get_mining_delay(self, omnitool_tier, proto)
    local BASE = 0.25 / omnitool_tier
    if not proto or not proto.solid then
        return 0
    end
    return (proto.tier + 1) * BASE
end

function MiningSystem.load(self)
    self.target = nil
end

function MiningSystem.update(self, dt)
    local player = Systems.get("player")
    local inv = player.inventory
    if not love.mouse.isDown(1) or inv.slots[inv.selected_slot].item_id ~= ITEMS.OMNITOOL then
        -- TODO or mouse moved to another target
        self:cancel_mining()
        return
    end
    -- Update mining progress if actively mining
    local world = Systems.get("world")
    local player_x, player_y, player_z = player:get_position()
    if not self.target then
        -- Start mining block
        local camera = Systems.get("camera")
        local camera_x, camera_y = camera:get_offset()
        local mx, my = love.mouse.getPosition()
        local world_x = mx + camera_x
        local world_y = my + camera_y
        local col, row = world:world_to_block(world_x, world_y)
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
end

function MiningSystem.start_mining(self, col, row)
    local player = Systems.get("player")
    local world = Systems.get("world")

    local player_x, player_y, player_z = player:get_position()
    local block_id = world:get_block_id(player_z, col, row)
    local proto = Registry.Blocks:get(block_id)

    if not proto or not proto.solid then
        return
    end

    -- DONT Check if player has omnitool equipped

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

function MiningSystem.cancel_mining(self)
    self.target = nil
end

function MiningSystem.complete_mining(self)
    if not self.target then
        return
    end

    local world = Systems.get("world")
    local z = self.target.z
    local col = self.target.col
    local row = self.target.row
    local proto = self.target.proto

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

    -- Reset mining state
    self:cancel_mining()
end

-- Draw mining progress overlay
function MiningSystem.draw(self)
    if not self.target then
        return
    end

    local camera = Systems.get("camera")
    local world = Systems.get("world")

    local camera_x, camera_y = camera:get_offset()
    local wx, wy = world:block_to_world(self.target.col, self.target.row)

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

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return MiningSystem
