-- Mining System
-- Handles block mining

local Systems = require "systems"
local Registry = require "registries"

local BLOCKS = Registry.blocks()

local MiningSystem = {
    id = "mining",
    priority = 60,
}

function MiningSystem.load(self)
    -- No need to store references, will use Systems.get
end

function MiningSystem.update(self, dt)
    -- Mining happens on mouse press, handled in mousepressed
end

function MiningSystem.mousepressed(self, x, y, button)
    if button ~= 1 then
        return
    end

    -- Get systems from G
    local world_system = Systems.get("world")
    local player_system = Systems.get("player")
    local camera_system = Systems.get("camera")

    if not world_system or not player_system or not camera_system then
        return
    end

    local camera_x, camera_y = camera_system:get_offset()
    local world_x = x + camera_x
    local world_y = y + camera_y

    local col, row = world_system:world_to_block(world_x, world_y)

    -- Left click: mine block
    self:mine_block(col, row, world_system, player_system)
end

function MiningSystem.mine_block(self, col, row, world_system, player_system)
    local player_x, player_y, player_z = player_system:get_position()
    local block_id = world_system:get_block_id(player_z, col, row)
    local proto = Registry.Blocks:get(block_id)

    if not proto or not proto.solid then
        return
    end

    -- Check tier requirement
    local player_tier = player_system:get_omnitool_tier()
    if proto.tier > player_tier then
        return -- Can't mine this yet
    end

    -- Remove block
    world_system:set_block(player_z, col, row, BLOCKS.AIR)

    -- Spawn drop
    if proto.drops then
        local drop_system = Systems.get("drop")
        if drop_system then
            local drop_id, drop_count = proto.drops()
            if drop_id then
                local wx, wy = world_system:block_to_world(col, row)
                drop_system.create_drop(drop_system,
                    wx + world_system.BLOCK_SIZE / 2,
                    wy + world_system.BLOCK_SIZE / 2,
                    player_z,
                    drop_id,
                    drop_count
                )
            end
        end
    end
end

return MiningSystem
