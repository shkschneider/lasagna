local Love = require "core.love"
local Object = require "core.object"
local Registry = require "src.game.registries"
local BLOCKS = Registry.blocks()
local ITEMS = Registry.items()

-- Visual constants for mining overlay
local MINING_OVERLAY_COLOR = {0, 0, 0, 0.5} -- Black with 80% opacity

local Mining = Object {
    id = "mining",
    priority = 60,
    -- Mining state
    target = nil, -- {z, col, row, progress, delay}
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
    Love.load(self)
end

function Mining.update(self, dt)
    local slot = G.player.hotbar:get_selected()
    if not love.mouse.isDown(1) or not slot or slot.item_id ~= ITEMS.OMNITOOL then
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

    -- Spawn drop
    if proto.drops then
        local drop_id, drop_count = proto.drops()
        if drop_id then
            local wx, wy = G.world:block_to_world(col, row)
            G.entities:newDrop(
                wx + BLOCK_SIZE / 2,
                wy + BLOCK_SIZE / 2,
                z,
                drop_id,
                drop_count
            )
        end
    end

    -- Reset mining state
    self:cancel_mining()
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

return Mining
