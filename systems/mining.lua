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
end

function MiningSystem.update(self, dt)
end

function MiningSystem.mousepressed(self, x, y, button)
    if button ~= 1 then
        return
    end

    -- Get systems from G
    local world = Systems.get("world")
    local player = Systems.get("player")
    local camera = Systems.get("camera")

    -- Check if player has a weapon item selected
    local inv = player.components.inventory
    local slot = inv.slots[inv.selected_slot]
    if slot and slot.item_id then
        -- Player has an item selected, not mining
        return
    end

    local camera_x, camera_y = camera:get_offset()
    local world_x = x + camera_x
    local world_y = y + camera_y

    local col, row = world:world_to_block(world_x, world_y)

    -- Left click: mine block
    self:mine_block(col, row, world, player)
end

function MiningSystem.mine_block(self, col, row, world, player)
    local player_x, player_y, player_z = player:get_position()
    local block_id = world:get_block_id(player_z, col, row)
    local proto = Registry.Blocks:get(block_id)

    if not proto or not proto.solid then
        return
    end

    -- Check tier requirement
    local player_tier = player:get_omnitool_tier()
    if proto.tier > player_tier then
        return -- Can't mine this yet
    end

    -- Remove block
    world:set_block(player_z, col, row, BLOCKS.AIR)

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
                    player_z,
                    drop_id,
                    drop_count
                )
            end
        end
    end
end

return MiningSystem
