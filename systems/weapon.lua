local Object = require "core.object"
local Registry = require "registries"
local ITEMS = Registry.items()

local Weapon = Object.new {
    id = "weapon",
    priority = 62,
    cooldown = 0,
    mouse_held = false,
}

function Weapon.load(self)
    self.cooldown = 0
    self.mouse_held = false
end

function Weapon.update(self, dt)
    -- Decrease cooldown
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - dt
    end

    -- Check if mouse button is held and cooldown is ready
    if self.mouse_held and self.cooldown <= 0 then
        self:try_shoot()
    end
end

function Weapon.try_shoot(self)
    -- Get selected item
    local inv = G.player.inventory
    local slot = inv.slots[inv.selected_slot]

    if not slot then
        return
    end

    -- Check if it's a weapon item
    local item_proto = Registry.Items:get(slot.item_id)
    if not item_proto or not item_proto.weapon then
        return
    end

    -- Get player position
    local player_x, player_y, player_z = G.player:get_position()

    -- Get mouse position in world coordinates
    local mouse_x, mouse_y = love.mouse.getPosition()
    local camera_x, camera_y = G.camera:get_offset()
    local world_mouse_x = mouse_x + camera_x
    local world_mouse_y = mouse_y + camera_y

    -- Calculate direction vector
    local dx = world_mouse_x - player_x
    local dy = world_mouse_y - player_y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 0 then
        dx = dx / dist
        dy = dy / dist
    end

    -- Create bullet
    local speed = item_proto.weapon.bullet_speed or 300
    local vx = dx * speed
    local vy = dy * speed

    G.bullet:newBullet(
        player_x,
        player_y,
        player_z,
        vx,
        vy,
        item_proto.weapon.bullet_width or 2,
        item_proto.weapon.bullet_height or 2,
        item_proto.weapon.bullet_color or {1, 1, 0, 1},
        item_proto.weapon.bullet_gravity or 0,
        item_proto.weapon.destroys_blocks or false
    )

    -- Set cooldown
    self.cooldown = item_proto.weapon.cooldown or 0.2
end

function Weapon.mousepressed(self, x, y, button)
    if button == 1 then
        self.mouse_held = true
        -- Try to shoot immediately
        if self.cooldown <= 0 then
            self:try_shoot()
        end
    end
end

function Weapon.mousereleased(self, x, y, button)
    if button == 1 then
        self.mouse_held = false
    end
end

return Weapon
