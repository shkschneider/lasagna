local Object = require("lib.object")
local log = require("lib.log")

local Navigation = Object {}

function Navigation:new(world, player, opts)
    assert(world)
    assert(player)
    self.world = world
    self.player = player
    self.opts = opts or {}
end

function Navigation:switch_layer(direction)
    if not self.player then return false, "no player" end
    if not self.world then return false, "no world provided" end
    if not direction or (direction ~= -1 and direction ~= 1) then
        return false, "invalid direction (must be -1 or 1)"
    end
    local current_z = self.player.z or 0
    local new_z = current_z + direction
    if new_z < C.LAYER_MIN then
        return false, "already at minimum layer"
    end
    if new_z > C.LAYER_MAX then
        return false, "already at maximum layer"
    end
    local x_pos = math.floor(self.player.px or 0)
    local surface_y = self.world:get_surface(new_z, x_pos) or (C.WORLD_HEIGHT - 1)
    self.player.z = new_z
    self.player.py = surface_y - self.player.height
    if self.player.vy then
        self.player.vy = 0
    end
    if log and log.info then
        log.info(string.format("Layer: %d", new_z))
    end

    return true, string.format("switched to layer %d", new_z)
end

function Navigation:get_current_layer()
    return self.player.z or 0
end

function Navigation:can_switch_to_layer(target_z)
    if target_z < C.LAYER_MIN then
        return false, "layer below minimum"
    end
    if target_z > C.LAYER_MAX then
        return false, "layer above maximum"
    end
    return true, "layer accessible"
end

function Navigation:teleport_to_layer(target_z)
    local can_move, reason = self:can_switch_to_layer(target_z)
    if not can_move then
        return false, reason
    end
    local x_pos = math.floor(self.player.px or 0)
    local surface_y = self.world:get_surface(target_z, x_pos) or (C.WORLD_HEIGHT - 1)
    self.player.z = target_z
    self.player.py = surface_y - self.player.height
    if self.player.vy then
        self.player.vy = 0
    end
    if log and log.info then
        log.info(string.format("Teleported to layer: %d", target_z))
    end
    return true, string.format("teleported to layer %d", target_z)
end

return Navigation
