local log = require("lib.log")

--- NavigationComponent: Handles player layer navigation and switching
--- This component manages switching between layers (z-axis movement) and
--- repositioning the player on the surface of the new layer.
---
--- Usage:
---   local Navigation = require("entities.components.navigation")
---   player.navigation = Navigation.new(player, {})
---   -- In keypressed:
---   if key == "q" then
---       player.navigation:switch_layer(-1, world)
---   elseif key == "e" then
---       player.navigation:switch_layer(1, world)
---   end

local Navigation = {}

--- Creates a new Navigation component
--- @param player table The player entity to attach to
--- @param opts table Optional configuration (currently unused)
--- @return table Navigation component instance
function Navigation.new(player, opts)
    opts = opts or {}
    
    local self = {
        player = player
    }
    
    setmetatable(self, { __index = Navigation })
    return self
end

--- Switches the player to a different layer
--- @param direction number Direction to move (-1 for down, 1 for up)
--- @param world table The world instance to query for surface position
--- @return boolean Success
--- @return string Message describing the result
function Navigation:switch_layer(direction, world)
    local player = self.player
    
    -- Defensive checks
    if not player then return false, "no player" end
    if not world then return false, "no world provided" end
    if not direction or (direction ~= -1 and direction ~= 1) then
        return false, "invalid direction (must be -1 or 1)"
    end
    
    -- Get current layer
    local current_z = player.z or 0
    local new_z = current_z + direction
    
    -- Check layer bounds
    local layer_min = C and C.LAYER_MIN or -1
    local layer_max = C and C.LAYER_MAX or 1
    
    if new_z < layer_min then
        return false, "already at minimum layer"
    end
    
    if new_z > layer_max then
        return false, "already at maximum layer"
    end
    
    -- Find surface position on the new layer
    local x_pos = math.floor(player.px or 0)
    local world_height = C and C.WORLD_HEIGHT or 100
    local surface_y = world:get_surface(new_z, x_pos) or (world_height - 1)
    
    -- Update player position
    local player_height = player.height or 2
    player.z = new_z
    player.py = surface_y - player_height
    
    -- Reset vertical velocity when changing layers
    if player.vy then
        player.vy = 0
    end
    
    -- Log the layer change
    if log and log.info then
        log.info(string.format("Layer: %d", new_z))
    end
    
    return true, string.format("switched to layer %d", new_z)
end

--- Gets the current layer the player is on
--- @return number Current layer z-coordinate
function Navigation:get_current_layer()
    return self.player.z or 0
end

--- Checks if the player can move to a specific layer
--- @param target_z number Target layer to check
--- @return boolean Can move to this layer
--- @return string Reason if cannot move
function Navigation:can_switch_to_layer(target_z)
    local layer_min = C and C.LAYER_MIN or -1
    local layer_max = C and C.LAYER_MAX or 1
    
    if target_z < layer_min then
        return false, "layer below minimum"
    end
    
    if target_z > layer_max then
        return false, "layer above maximum"
    end
    
    return true, "layer accessible"
end

--- Teleports the player to a specific layer
--- Useful for scripted events or special navigation mechanics
--- @param target_z number Target layer z-coordinate
--- @param world table The world instance
--- @return boolean Success
--- @return string Message
function Navigation:teleport_to_layer(target_z, world)
    local player = self.player
    
    if not world then return false, "no world provided" end
    
    -- Validate target layer
    local can_move, reason = self:can_switch_to_layer(target_z)
    if not can_move then
        return false, reason
    end
    
    -- Find surface on target layer
    local x_pos = math.floor(player.px or 0)
    local world_height = C and C.WORLD_HEIGHT or 100
    local surface_y = world:get_surface(target_z, x_pos) or (world_height - 1)
    
    -- Update position
    local player_height = player.height or 2
    player.z = target_z
    player.py = surface_y - player_height
    
    if player.vy then
        player.vy = 0
    end
    
    if log and log.info then
        log.info(string.format("Teleported to layer: %d", target_z))
    end
    
    return true, string.format("teleported to layer %d", target_z)
end

return Navigation
