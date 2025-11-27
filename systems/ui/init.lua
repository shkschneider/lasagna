local Love = require "core.love"
local Object = require "core.object"
local Registry = require "registries"
local Canvases = require "systems.ui.canvases"

local InterfaceSystem = Object {
    id = "interface",
    priority = 110,
}

function InterfaceSystem.draw(self)
    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()

    local camera_x, camera_y = G.camera:get_offset()
    local pos = G.player.position
    local hotbar = G.player.hotbar
    local omnitool = G.player.omnitool

    -- Draw to UI canvas
    love.graphics.setCanvas(Canvases.ui)
    love.graphics.clear(0, 0, 0, 0)

    -- Draw cursor highlight
    self:draw_cursor_highlight(camera_x, camera_y, pos.z)

    -- Layer indicator
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Layer: %d", pos.z), 10, 10)

    -- Omnitool tier
    love.graphics.print(string.format("OmniTool: %s", omnitool:tostring()), 10, 30)

    -- Player position
    local block_x, block_y = G.world:world_to_block(pos.x, pos.y)
    love.graphics.print(string.format("Position: %d, %d", block_x, block_y), 10, 50)

    -- Mouse position and block under cursor
    local mouse_x, mouse_y = love.mouse.getPosition()
    local world_x = mouse_x + camera_x
    local world_y = mouse_y + camera_y
    local mouse_col, mouse_row = G.world:world_to_block(world_x, world_y)
    local block_def = G.world:get_block_def(pos.z, mouse_col, mouse_row)
    local block_name = block_def and block_def.name or "Air"
    love.graphics.print(string.format("Mouse: %d, %d (%s)", mouse_col, mouse_row, block_name), 10, 70)

    -- Draw hotbar
    local hotbar_y = screen_height - 80
    local slot_size = 60
    local hotbar_x = (screen_width - (hotbar.size * slot_size)) / 2

    for i = 1, hotbar.size do
        local x = hotbar_x + (i - 1) * slot_size

        -- Slot background
        love.graphics.setColor(0, 0, 0, 0.33)
        love.graphics.rectangle("fill", x, hotbar_y, slot_size - 2, slot_size - 2)

        -- Slot border
        if i == hotbar.selected_slot then
            love.graphics.setColor(1, 1, 0, 0.5) -- Yellow for selected
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        end
        love.graphics.rectangle("line", x, hotbar_y, slot_size - 4, slot_size - 4)

        -- Item in slot
        local slot = hotbar:get_slot(i)
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
    local selected_slot = hotbar:get_selected()
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

    love.graphics.setCanvas()

    Love.draw(self)
end

-- Draw cursor highlight for block under cursor
function InterfaceSystem.draw_cursor_highlight(self, camera_x, camera_y, player_z)
    -- Get mouse position
    local mouse_x, mouse_y = love.mouse.getPosition()
    local world_x = mouse_x + camera_x
    local world_y = mouse_y + camera_y

    -- Convert to block coordinates
    local col, row = G.world:world_to_block(world_x, world_y)

    -- Get block at cursor position
    local block_id = G.world:get_block_id(player_z, col, row)
    local proto = Registry.Blocks:get(block_id)

    -- Calculate screen position
    local screen_x = col * BLOCK_SIZE - camera_x
    local screen_y = row * BLOCK_SIZE - camera_y

    -- Check if block exists (solid block)
    if proto and proto.solid then
        -- Draw white 1px border for existing blocks
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", screen_x, screen_y, BLOCK_SIZE, BLOCK_SIZE)
    else
        -- Block is air, check if it's a valid building location
        if G.world:is_valid_building_location(col, row, player_z) then
            -- Draw black 1px border for valid building locations
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", screen_x, screen_y, BLOCK_SIZE, BLOCK_SIZE)
        end
    end
end

return InterfaceSystem
