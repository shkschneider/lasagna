-- Mining System
-- Handles block mining and placing

local blocks = require("core.blocks")

local MiningSystem = {
    priority = 60,
}

function MiningSystem.load(self, world_system, player_system, drop_system)
    self.world_system = world_system
    self.player_system = player_system
    self.drop_system = drop_system
end

function MiningSystem.update(self, dt)
    -- Mining happens on mouse press, handled in mousepressed
end

function MiningSystem.mousepressed(self, x, y, button, camera_x, camera_y)
    local world_x = x + camera_x
    local world_y = y + camera_y

    local col, row = self.world_system:world_to_block(world_x, world_y)

    if button == 1 then
        -- Left click: mine block
        self.mine_block(self, col, row)
    elseif button == 2 then
        -- Right click: place block
        self.place_block(self, col, row)
    end
end

function MiningSystem.mine_block(self, col, row)
    local player_x, player_y, player_layer = self.player_system:get_position()
    local block_id = self.world_system:get_block(player_layer, col, row)
    local proto = blocks.get_proto(block_id)

    if not proto or not proto.solid then
        return
    end

    -- Check tier requirement
    local player_tier = self.player_system:get_omnitool_tier()
    if proto.tier > player_tier then
        return -- Can't mine this yet
    end

    -- Remove block
    self.world_system:set_block(player_layer, col, row, blocks.AIR)

    -- Spawn drop
    if proto.drops and self.drop_system then
        local drop_id, drop_count = proto.drops()
        if drop_id then
            local wx, wy = self.world_system:block_to_world(col, row)
            self.drop_system:create_drop(
                wx + self.world_system.BLOCK_SIZE / 2,
                wy + self.world_system.BLOCK_SIZE / 2,
                player_layer,
                drop_id,
                drop_count
            )
        end
    end
end

function MiningSystem.place_block(self, col, row)
    local player_x, player_y, player_layer = self.player_system:get_position()
    local block_id = self.player_system:get_selected_block_id()

    if not block_id then
        return
    end

    -- Check if spot is empty
    local current_block = self.world_system:get_block(player_layer, col, row)
    if current_block ~= blocks.AIR then
        return
    end

    -- Place block
    if self.world_system:set_block(player_layer, col, row, block_id) then
        -- Remove from inventory
        self.player_system:remove_from_selected(1)
    end
end

return MiningSystem
