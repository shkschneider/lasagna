local log = require("lib.log")

--- InteractionComponent: Handles player block placement and removal interactions
--- This component provides methods to place and remove blocks at mouse positions,
--- implementing the same behavior as Player's placeAtMouse/removeAtMouse methods
--- but as a standalone component.
---
--- Usage:
---   local Interaction = require("entities.components.interaction")
---   player.interaction = Interaction.new(player, {})
---   local ok, msg, z = player.interaction:place_block_at_mouse(world, camera_x, block_size, mx, my)

local Interaction = {}

--- Creates a new Interaction component
--- @param player table The player entity to attach to
--- @param opts table Optional configuration (currently unused)
--- @return table Interaction component instance
function Interaction.new(player, opts)
    opts = opts or {}
    
    local self = {
        player = player
    }
    
    setmetatable(self, { __index = Interaction })
    return self
end

--- Places a block at the mouse position
--- @param world table The world instance
--- @param camera_x number Camera x offset in pixels
--- @param block_size number Size of a block in pixels
--- @param mx number Mouse x position in screen coordinates
--- @param my number Mouse y position in screen coordinates
--- @param z_override number Optional layer override (unused, for API compatibility)
--- @return boolean Success
--- @return string Message/error description
--- @return number Layer where action was attempted
function Interaction:place_block_at_mouse(world, camera_x, block_size, mx, my, z_override)
    local player = self.player
    
    -- Defensive checks
    if not world then return false, "no world provided", 0 end
    if not player then return false, "no player", 0 end
    
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then
        return false, "no mouse position provided", player.z or 0
    end
    
    -- Get selected item from player inventory
    local inv = player.inventory
    if not inv then return false, "no inventory", player.z or 0 end
    
    local selected = inv.selected or 1
    local item = inv.items and inv.items[selected]
    if not item then return false, "no item selected", player.z or 0 end
    
    -- Calculate world position
    local world_px = mouse_x + (camera_x or 0)
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(mouse_y / block_size) + 1
    
    -- Clamp row to world height
    local world_height = C and C.WORLD_HEIGHT or 100
    row = math.max(1, math.min(world_height, row))
    
    -- Get player's current layer
    local z = player.z or 0
    
    -- Check if target is empty
    local target = world:get_block_type(z, col, row)
    if target ~= "air" then
        return false, "target not empty", z
    end
    
    -- Check if placement touches an existing block
    local touches_existing = false
    for dx = -1, 1 do
        for dy = -1, 1 do
            if not (dx == 0 and dy == 0) then
                local nx, ny = col + dx, row + dy
                if ny >= 1 and ny <= world_height then
                    local neigh = world:get_block_type(z, nx, ny)
                    if neigh and neigh ~= "air" and neigh ~= "out" then
                        touches_existing = true
                        break
                    end
                end
            end
        end
        if touches_existing then break end
    end
    
    if not touches_existing then
        return false, "must touch an existing block on the same layer", z
    end
    
    -- Place the block
    local ok, action = world:set_block(z, col, row, item)
    return ok, action, z
end

--- Removes a block at the mouse position
--- @param world table The world instance
--- @param camera_x number Camera x offset in pixels
--- @param block_size number Size of a block in pixels
--- @param mx number Mouse x position in screen coordinates
--- @param my number Mouse y position in screen coordinates
--- @param z_override number Optional layer override (unused, for API compatibility)
--- @return boolean Success
--- @return string Message/error description
--- @return number Layer where action was attempted
function Interaction:remove_block_at_mouse(world, camera_x, block_size, mx, my, z_override)
    local player = self.player
    
    -- Defensive checks
    if not world then return false, "no world provided", 0 end
    if not player then return false, "no player", 0 end
    
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then
        return false, "no mouse position provided", player.z or 0
    end
    
    -- Calculate world position
    local world_px = mouse_x + (camera_x or 0)
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(mouse_y / block_size) + 1
    
    -- Clamp row to world height
    local world_height = C and C.WORLD_HEIGHT or 100
    row = math.max(1, math.min(world_height, row))
    
    -- Get player's current layer
    local z = player.z or 0
    
    -- Check if there's a block to remove
    local t = world:get_block_type(z, col, row)
    if not t or t == "air" or t == "out" then
        return false, "nothing to remove", z
    end
    
    -- Try to remove the block
    local ok, msg = world:set_block(z, col, row, nil)
    if ok then
        if log and log.info then
            log.info(string.format("Removed block at z=%d, col=%d, row=%d", z, col, row))
        end
        return true, msg, z
    end
    
    -- If removal failed, try marking as empty (for procedurally generated blocks)
    local ok2, msg2 = world:set_block(z, col, row, "__empty")
    if ok2 then
        if log and log.info then
            log.info(string.format("Marked procedural block removed at z=%d, col=%d, row=%d", z, col, row))
        end
        return true, msg2, z
    end
    
    return false, "failed to remove block", z
end

return Interaction
