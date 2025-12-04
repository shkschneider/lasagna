-- Crafting UI
-- Displays crafting interface with dummy items for prototyping

local CraftUI = {}

-- Draw the crafting interface
-- @param x: X position
-- @param y: Y position
-- @param size: Size of the crafting area
function CraftUI.draw(x, y, size)
    local padding = 5
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x, y, size, size)
    
    -- Border
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", x, y, size, size)
    
    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Crafting", x + padding, y + padding)
    
    -- Dummy crafting slots (3x3 grid)
    local slot_size = 24
    local grid_start_x = x + padding
    local grid_start_y = y + padding + 20
    local slot_padding = 4
    
    for row = 0, 2 do
        for col = 0, 2 do
            local slot_x = grid_start_x + col * (slot_size + slot_padding)
            local slot_y = grid_start_y + row * (slot_size + slot_padding)
            
            -- Slot background
            love.graphics.setColor(0, 0, 0, 0.33)
            love.graphics.rectangle("fill", slot_x, slot_y, slot_size, slot_size)
            
            -- Slot border
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
            love.graphics.rectangle("line", slot_x, slot_y, slot_size, slot_size)
        end
    end
    
    -- Arrow pointing to result
    local arrow_x = grid_start_x + 3 * (slot_size + slot_padding) + 10
    local arrow_y = grid_start_y + slot_size
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("=>", arrow_x, arrow_y)
    
    -- Result slot
    local result_x = arrow_x + 30
    local result_y = grid_start_y + slot_size
    love.graphics.setColor(0, 0, 0, 0.33)
    love.graphics.rectangle("fill", result_x, result_y, slot_size, slot_size)
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", result_x, result_y, slot_size, slot_size)
    
    -- Craft button
    local button_width = size - padding * 2
    local button_height = 30
    local button_x = x + padding
    local button_y = y + size - button_height - padding
    
    -- Check if mouse is over button
    local mouse_x, mouse_y = love.mouse.getPosition()
    local is_hovered = mouse_x >= button_x and mouse_x <= button_x + button_width and
                       mouse_y >= button_y and mouse_y <= button_y + button_height
    
    if is_hovered then
        love.graphics.setColor(0.4, 0.6, 0.4, 0.8)
    else
        love.graphics.setColor(0.2, 0.4, 0.2, 0.8)
    end
    love.graphics.rectangle("fill", button_x, button_y, button_width, button_height)
    
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", button_x, button_y, button_width, button_height)
    
    love.graphics.setColor(1, 1, 1, 1)
    local button_text = "CRAFT (dummy)"
    local text_width = love.graphics.getFont():getWidth(button_text)
    love.graphics.print(button_text, button_x + button_width / 2 - text_width / 2, button_y + 8)
end

-- Check if craft button is clicked
-- NOTE: This function is currently unused but kept for future crafting implementation
-- @param x: X position of craft UI
-- @param y: Y position of craft UI
-- @param size: Size of the crafting area
-- @param mouse_x: Mouse X position
-- @param mouse_y: Mouse Y position
-- @return true if button was clicked
function CraftUI.is_craft_button_clicked(x, y, size, mouse_x, mouse_y)
    local padding = 5
    local button_width = size - padding * 2
    local button_height = 30
    local button_x = x + padding
    local button_y = y + size - button_height - padding
    
    return mouse_x >= button_x and mouse_x <= button_x + button_width and
           mouse_y >= button_y and mouse_y <= button_y + button_height
end

return CraftUI
