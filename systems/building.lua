-- Building System
-- Handles block placing

local Systems = require "systems"
local Registry = require "registries"

local BLOCKS = Registry.blocks()

local BuildingSystem = {
    id = "building",
    priority = 61,
}

function BuildingSystem.load(self)
    -- No need to store references, will use Systems.get
end

function BuildingSystem.update(self, dt)
    -- Building happens on mouse press, handled in mousepressed
end

function BuildingSystem.mousepressed(self, x, y, button)
    if button ~= 2 then
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

    -- Right click: place block
    self:place_block(col, row, world_system, player_system)
end

function BuildingSystem.has_adjacent_block(self, col, row, layer, world_system)
    -- Check all 8 surrounding positions for solid blocks
    local offsets = {
        {-1, -1}, {0, -1}, {1, -1},  -- top row
        {-1,  0},          {1,  0},  -- middle row (left and right)
        {-1,  1}, {0,  1}, {1,  1},  -- bottom row
    }
    
    for _, offset in ipairs(offsets) do
        local check_col = col + offset[1]
        local check_row = row + offset[2]
        local proto = world_system:get_block_proto(layer, check_col, check_row)
        if proto and proto.solid then
            return true
        end
    end
    
    return false
end

function BuildingSystem.place_block(self, col, row, world_system, player_system)
    local player_x, player_y, player_layer = player_system:get_position()
    local block_id = player_system:get_selected_block_id()

    if not block_id then
        return
    end

    -- Check if spot is empty
    local current_block = world_system:get_block(player_layer, col, row)
    if current_block ~= BLOCKS.AIR then
        return
    end

    -- Check if there's at least one adjacent solid block
    if not self:has_adjacent_block(col, row, player_layer, world_system) then
        return
    end

    -- Place block
    if world_system:set_block(player_layer, col, row, block_id) then
        -- Remove from inventory
        player_system:remove_from_selected(1)
    end
end

return BuildingSystem
