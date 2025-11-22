-- UI System
-- Handles user interface rendering

local Systems = require "systems"
local Registry = require "registries"

local UISystem = {
    id = "ui",
    priority = 110,
}

function UISystem.load(self)
    self.screen_width, self.screen_height = love.graphics.getDimensions()
end

function UISystem.draw(self)
    local player_system = Systems.get("player")
    local world_system = Systems.get("world")
    local camera_system = Systems.get("camera")

    if not player_system or not world_system or not camera_system then
        return
    end

    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()

    local camera_x, camera_y = camera_system:get_offset()
    local pos = player_system.components.position
    local inv = player_system.components.inventory
    local omnitool = player_system.components.omnitool

    -- Layer indicator
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Layer: %d", pos.z), 10, 10)

    -- Omnitool tier
    love.graphics.print(string.format("Omnitool Tier: %d", omnitool.tier), 10, 30)

    -- Player position
    local block_x, block_y = world_system:world_to_block(pos.x, pos.y)
    love.graphics.print(string.format("Position: %d, %d", block_x, block_y), 10, 50)

    -- Mouse position and block under cursor
    local mouse_x, mouse_y = love.mouse.getPosition()
    local world_x = mouse_x + camera_x
    local world_y = mouse_y + camera_y
    local mouse_col, mouse_row = world_system:world_to_block(world_x, world_y)
    local block_def = world_system:get_block_def(pos.z, mouse_col, mouse_row)
    local block_name = block_def and block_def.name or "Air"
    love.graphics.print(string.format("Mouse: %d, %d (%s)", mouse_col, mouse_row, block_name), 10, 70)

    -- Draw hotbar
    local hotbar_y = screen_height - 80
    local slot_size = 60
    local hotbar_x = (screen_width - (inv.hotbar_size * slot_size)) / 2

    for i = 1, inv.hotbar_size do
        local x = hotbar_x + (i - 1) * slot_size

        -- Slot background
        if i == inv.selected_slot then
            love.graphics.setColor(1, 1, 0, 0.5) -- Yellow for selected
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        end
        love.graphics.rectangle("fill", x, hotbar_y, slot_size - 4, slot_size - 4)

        -- Slot border
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.rectangle("line", x, hotbar_y, slot_size - 4, slot_size - 4)

        -- Item in slot
        local slot = inv.slots[i]
        if slot then
            local proto = Registry.Blocks:get(slot.block_id)
            if proto then
                -- Draw item as colored square
                love.graphics.setColor(proto.color)
                love.graphics.rectangle("fill", x + 8, hotbar_y + 8, slot_size - 20, slot_size - 20)

                -- Draw count
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(tostring(slot.count), x + 4, hotbar_y + slot_size - 20)
            end
        end
    end

    -- Selected item name above hotbar
    local selected_slot = inv.slots[inv.selected_slot]
    if selected_slot then
        local proto = Registry.Blocks:get(selected_slot.block_id)
        if proto then
            love.graphics.setColor(1, 1, 1, 1)
            local text = proto.name
            local text_width = love.graphics.getFont():getWidth(text)
            love.graphics.print(text, (screen_width - text_width) / 2, hotbar_y - 25)
        end
    end
end

function UISystem.resize(self, width, height)
    self.screen_width = width
    self.screen_height = height
end

return UISystem
