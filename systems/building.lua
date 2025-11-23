-- Building System
-- Handles block placing

local Systems = require "systems"
local Registry = require "registries"

local BLOCKS = Registry.blocks()

-- Layer constants
local MIN_LAYER = -1
local MAX_LAYER = 1

local BuildingSystem = {
    id = "building",
    priority = 61,
}

function BuildingSystem.load(self) end

function BuildingSystem.update(self, dt) end

function BuildingSystem.mousepressed(self, x, y, button)
    if button ~= 2 then
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

    -- Right click: place block
    self:place_block(col, row)
end

function BuildingSystem.has_adjacent_block(self, col, row, layer)
    local world = Systems.get("world")

    -- Check all 8 surrounding positions for solid blocks in the same layer
    local offsets = {
        {-1, -1}, {0, -1}, {1, -1},  -- top row
        {-1,  0},          {1,  0},  -- middle row (left and right)
        {-1,  1}, {0,  1}, {1,  1},  -- bottom row
    }

    for _, offset in ipairs(offsets) do
        local check_col = col + offset[1]
        local check_row = row + offset[2]
        local proto = world:get_block_def(layer, check_col, check_row)
        if proto and proto.solid then
            return true
        end
    end

    return false
end

function BuildingSystem.has_adjacent_layer_block(self, col, row, layer)
    local world = Systems.get("world")
    
    -- Check for solid blocks at the same position in layers above and below
    
    -- Check layer below (if not already at bottom layer)
    if layer - 1 >= MIN_LAYER then
        local proto = world:get_block_def(layer - 1, col, row)
        if proto and proto.solid then
            return true
        end
    end
    
    -- Check layer above (if not already at top layer)
    if layer + 1 <= MAX_LAYER then
        local proto = world:get_block_def(layer + 1, col, row)
        if proto and proto.solid then
            return true
        end
    end
    
    return false
end

function BuildingSystem.place_block(self, col, row)
    local world = Systems.get("world")
    local player = Systems.get("player")

    local player_x, player_y, player_z = player:get_position()
    local block_id = player:get_selected_block_id()

    if not block_id then
        return
    end

    -- Check if spot is empty
    local current_block = world:get_block_id(player_z, col, row)
    if current_block ~= BLOCKS.AIR then
        return
    end

    -- Check if there's at least one adjacent solid block in same layer OR in adjacent layers
    local has_same_layer_adjacent = self:has_adjacent_block(col, row, player_z)
    local has_adjacent_layer = self:has_adjacent_layer_block(col, row, player_z)
    
    -- Allow placement if:
    -- 1. There's a solid block in the same layer adjacent, OR
    -- 2. There's a solid block in an adjacent layer at the same position
    -- This prevents completely floating blocks while allowing vertical connections
    if not has_same_layer_adjacent and not has_adjacent_layer then
        return
    end

    -- Place block
    if world:set_block(player_z, col, row, block_id) then
        -- Remove from inventory
        player:remove_from_selected(1)
    end
end

return BuildingSystem
