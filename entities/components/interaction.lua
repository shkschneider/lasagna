local Object = require("lib.object")
local log = require("lib.log")

local Interaction = Object {}

function Inventory:new(player, opts)
    assert(player)
    opts = opts or {}
    self.player = player
end

function Interaction:place_block_at_mouse(world, camera_x, block_size, mx, my, z_override)
    local player = self.player
    if not world then return false, "no world provided", 0 end
    if not player then return false, "no player", 0 end
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then
        return false, "no mouse position provided", player.z or 0
    end
    local inv = player.inventory
    if not inv then return false, "no inventory", player.z or 0 end
    local selected = inv.selected or 1
    local item = inv.items and inv.items[selected]
    if not item then return false, "no item selected", player.z or 0 end
    local world_px = mouse_x + (camera_x or 0)
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(mouse_y / block_size) + 1
    local world_height = C and C.WORLD_HEIGHT or 100
    row = math.max(1, math.min(world_height, row))
    local z = player.z or 0
    local target = world:get_block_type(z, col, row)
    if target ~= "air" then
        return false, "target not empty", z
    end
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
    local ok, action = world:set_block(z, col, row, item)
    return ok, action, z
end

function Interaction:remove_block_at_mouse(world, camera_x, block_size, mx, my, z_override)
    local player = self.player
    if not world then return false, "no world provided", 0 end
    if not player then return false, "no player", 0 end
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then
        return false, "no mouse position provided", player.z or 0
    end
    local world_px = mouse_x + (camera_x or 0)
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(mouse_y / block_size) + 1
    local world_height = C and C.WORLD_HEIGHT or 100
    row = math.max(1, math.min(world_height, row))
    local z = player.z or 0
    local t = world:get_block_type(z, col, row)
    if not t or t == "air" or t == "out" then
        return false, "nothing to remove", z
    end
    local ok, msg = world:set_block(z, col, row, nil)
    if ok then
        log.debug(string.format("Removed block at z=%d, col=%d, row=%d", z, col, row))
        return true, msg, z
    else
        local ok2, msg2 = world:set_block(z, col, row, "__empty")
        if ok2 then
            log.debug(string.format("Removed block '%s' at x=%d y=%d z=%", "?", col, row, z)
        end
        return true, msg2, z
    end
    return false, "failed to remove block", z
end

return Interaction
