-- Mining System
-- Handles block mining and placing

local blocks = require("core.blocks")

local MiningSystem = {
    id = "mining",
    priority = 60,
}

function MiningSystem.load(self)
    -- No need to store references, will use G.get_system
end

function MiningSystem.update(self, dt)
    -- Mining happens on mouse press, handled in mousepressed
end

function MiningSystem.mousepressed(self, x, y, button)
    -- Get systems from G
    local world_system = G:get_system("world")
    local player_system = G:get_system("player")
    local camera_system = G:get_system("camera")

    if not world_system or not player_system or not camera_system then
        return
    end

    local camera_x, camera_y = camera_system:get_offset()
    local world_x = x + camera_x
    local world_y = y + camera_y

    local col, row = world_system:world_to_block(world_x, world_y)

    if button == 1 then
        -- Left click: mine block
        self:mine_block(col, row, world_system, player_system)
    elseif button == 2 then
        -- Right click: place block
        self:place_block(col, row, world_system, player_system)
    end
end

function MiningSystem.mine_block(self, col, row, world_system, player_system)
    local player_x, player_y, player_layer = player_system:get_position()
    local block_id = world_system:get_block(player_layer, col, row)
    local proto = blocks.get_proto(block_id)

    if not proto or not proto.solid then
        return
    end

    -- Check tier requirement
    local player_tier = player_system:get_omnitool_tier()
    if proto.tier > player_tier then
        return -- Can't mine this yet
    end

    -- Remove block
    world_system:set_block(player_layer, col, row, blocks.AIR)

    -- Spawn drop
    if proto.drops then
        local drop_system = G:get_system("drop")
        if drop_system then
            local drop_id, drop_count = proto.drops()
            if drop_id then
                local wx, wy = world_system:block_to_world(col, row)
                drop_system.create_drop(drop_system,
                    wx + world_system.BLOCK_SIZE / 2,
                    wy + world_system.BLOCK_SIZE / 2,
                    player_layer,
                    drop_id,
                    drop_count
                )
            end
        end
    end
end

function MiningSystem.place_block(self, col, row, world_system, player_system)
    local player_x, player_y, player_layer = player_system:get_position()
    local block_id = player_system:get_selected_block_id()

    if not block_id then
        return
    end

    -- Check if spot is empty
    local current_block = world_system:get_block(player_layer, col, row)
    if current_block ~= blocks.AIR then
        return
    end

    -- Place block
    if world_system:set_block(player_layer, col, row, block_id) then
        -- Remove from inventory
        player_system:remove_from_selected(1)
    end
end

return MiningSystem
