-- UI System
-- Handles user interface rendering

local Object = require "core.object"
local Systems = require "systems"
local Registry = require "registries"

local UISystem = Object.new {
    id = "ui",
    priority = 110,
}

function UISystem.load(self) end

function UISystem.draw(self)
    local player = Systems.get("player")
    local world = Systems.get("world")
    local camera = Systems.get("camera")

    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()

    local camera_x, camera_y = camera:get_offset()
    local pos = player.position
    local inv = player.inventory
    local omnitool = player.omnitool

    -- Layer indicator
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Layer: %d", pos.z), 10, 10)

    -- Omnitool tier
    love.graphics.print(string.format("OmniTool: %s", omnitool:tostring()), 10, 30)

    -- Player position
    local block_x, block_y = world:world_to_block(pos.x, pos.y)
    love.graphics.print(string.format("Position: %d, %d", block_x, block_y), 10, 50)

    -- Mouse position and block under cursor
    local mouse_x, mouse_y = love.mouse.getPosition()
    local world_x = mouse_x + camera_x
    local world_y = mouse_y + camera_y
    local mouse_col, mouse_row = world:world_to_block(world_x, world_y)
    local block_def = world:get_block_def(pos.z, mouse_col, mouse_row)
    local block_name = block_def and block_def.name or "Air"
    love.graphics.print(string.format("Mouse: %d, %d (%s)", mouse_col, mouse_row, block_name), 10, 70)

    -- Draw hotbar
    local hotbar_y = screen_height - 80
    local slot_size = 60
    local hotbar_x = (screen_width - (inv.hotbar_size * slot_size)) / 2

    -- Draw health bar above hotbar
    local health = player.health
    local stamina = player.stamina
    if health and health.max > 0 then
        local health_bar_height = BLOCK_SIZE / 4  -- 1/4 BLOCK_SIZE high
        local hotbar_width = inv.hotbar_size * slot_size
        local health_bar_width = hotbar_width / 2  -- Half the hotbar width
        local health_bar_x = hotbar_x  -- Aligned left
        local health_bar_y = hotbar_y - health_bar_height - 10  -- 10px above hotbar

        -- Health bar background
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", health_bar_x, health_bar_y, health_bar_width, health_bar_height)

        -- Health bar fill
        local health_percentage = health.current / health.max
        local health_fill_width = health_bar_width * health_percentage

        -- Color based on health percentage
        if health_percentage > 0.6 then
            love.graphics.setColor(0, 1, 0, 0.8)  -- Green
        elseif health_percentage > 0.3 then
            love.graphics.setColor(1, 1, 0, 0.8)  -- Yellow
        else
            love.graphics.setColor(1, 0, 0, 0.8)  -- Red
        end
        love.graphics.rectangle("fill", health_bar_x, health_bar_y, health_fill_width, health_bar_height)
    end

    -- Draw stamina bar above hotbar (right side)
    if stamina and stamina.max > 0 then
        local stamina_bar_height = BLOCK_SIZE / 4  -- 1/4 BLOCK_SIZE high
        local hotbar_width = inv.hotbar_size * slot_size
        local stamina_bar_width = hotbar_width / 2  -- Half the hotbar width
        local stamina_bar_x = hotbar_x + hotbar_width / 2  -- Aligned right (after health bar)
        local stamina_bar_y = hotbar_y - stamina_bar_height - 10  -- 10px above hotbar

        -- Stamina bar background
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", stamina_bar_x, stamina_bar_y, stamina_bar_width, stamina_bar_height)

        -- Stamina bar fill
        local stamina_percentage = stamina.current / stamina.max
        local stamina_fill_width = stamina_bar_width * stamina_percentage

        -- Blue color for stamina
        love.graphics.setColor(0, 0.5, 1, 0.8)  -- Blue
        love.graphics.rectangle("fill", stamina_bar_x, stamina_bar_y, stamina_fill_width, stamina_bar_height)
    end

    for i = 1, inv.hotbar_size do
        local x = hotbar_x + (i - 1) * slot_size

        -- Slot background
        love.graphics.setColor(0, 0, 0, 0.33)
        love.graphics.rectangle("fill", x, hotbar_y, slot_size - 2, slot_size - 2)

        -- Slot border
        if i == inv.selected_slot then
            love.graphics.setColor(1, 1, 0, 0.5) -- Yellow for selected
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        end
        love.graphics.rectangle("line", x, hotbar_y, slot_size - 4, slot_size - 4)

        -- Item in slot
        local slot = inv.slots[i]
        if slot then
            local proto = nil
            local color = nil

            if slot.block_id then
                proto = Registry.Blocks:get(slot.block_id)
                if proto then
                    color = proto.color
                end
            elseif slot.item_id then
                proto = Registry.Items:get(slot.item_id)
                if proto and proto.weapon then
                    -- Use weapon bullet color for display
                    color = proto.weapon.bullet_color or {1, 1, 1, 1}
                else
                    color = {1, 1, 1, 1}
                end
            end

            if proto and color then
                -- Draw item as colored square
                love.graphics.setColor(color)
                love.graphics.rectangle("fill", x + 8, hotbar_y + 8, slot_size - 20, slot_size - 20)

                -- Draw count
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(tostring(slot.count), x + slot_size / 4, hotbar_y + slot_size - 20 - 10)
            end
        end
    end

    -- Selected item name above hotbar
    local selected_slot = inv.slots[inv.selected_slot]
    if selected_slot then
        local proto = nil

        if selected_slot.block_id then
            proto = Registry.Blocks:get(selected_slot.block_id)
        elseif selected_slot.item_id then
            proto = Registry.Items:get(selected_slot.item_id)
        end

        if proto then
            love.graphics.setColor(1, 1, 1, 1)
            local text = proto.name
            local text_width = love.graphics.getFont():getWidth(text)
            love.graphics.print(text, (screen_width - text_width) / 2, hotbar_y - 40)
        end
    end
end

return UISystem
