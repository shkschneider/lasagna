local Love = require "core.love"
local Object = require "core.object"
local Registry = require "src.registries"
local TiersUI = require "src.ui.tiers"
local CraftUI = require "src.ui.craft"

local Interface = Object {
    id = "interface",
    priority = 110,
}

function Interface.draw(self)
    -- Get current screen dimensions dynamically
    local screen_width, screen_height = love.graphics.getDimensions()

    local camera_x, camera_y = G.camera:get_offset()
    local pos = G.player.position
    local hotbar = G.player.hotbar
    local backpack = G.player.backpack
    local inventory_open = G.player.inventory_open

    -- Draw cursor highlight
    self:draw_cursor_highlight(camera_x, camera_y, pos.z)

    -- Draw lookup (center top)
    local mouse_x, mouse_y = love.mouse.getPosition()
    local world_x = mouse_x + camera_x
    local world_y = mouse_y + camera_y
    local mouse_col, mouse_row = G.world:world_to_block(world_x, world_y)
    local block_def = G.world:get_block_def(pos.z, mouse_col, mouse_row)
    local block_name = block_def and block_def.name or "Air"
    local biome_name = G.world:get_biome(world_x, world_y, pos.z).name
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("[%s] %s", biome_name, block_name), screen_width / 2, 10)

    -- Draw inventory (hotbar + backpack if open)
    local slot_size = BLOCK_SIZE * 2  -- 2*BLOCK_SIZE width and height
    local hotbar_x = 10
    local hotbar_y = 10
    local padding = 5  -- Padding around the inventory box

    -- Calculate background dimensions
    local hotbar_width = hotbar.size * slot_size
    local hotbar_height = slot_size
    local total_height = hotbar_height
    if inventory_open then
        total_height = hotbar_height + (3 * slot_size)  -- hotbar + 3 rows of backpack
    end

    -- Draw semi-transparent black background box below and around hotbar (and backpack)
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill",
        hotbar_x - padding,
        hotbar_y - padding,
        hotbar_width + padding * 2,
        total_height + padding * 2)

    -- Draw hotbar slots
    self:draw_inventory_slots(hotbar, hotbar_x, hotbar_y, slot_size, 9, true)

    -- Draw backpack when inventory is open
    if inventory_open then
        love.graphics.setColor(0, 0, 0, 0.33)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
        local backpack_y = hotbar_y + slot_size  -- Start right below hotbar
        self:draw_inventory_slots(backpack, hotbar_x, backpack_y, slot_size, 9, false)
        
        -- Draw progression/tier UI below inventory
        local tiers_y = hotbar_y + total_height + 30  -- Below selected item name
        local tiers_width = hotbar_width
        local tiers_height = 40
        TiersUI.draw(hotbar_x, tiers_y, tiers_width, tiers_height, 
                     G.player:get_omnitool_tier(), G.player.omnitool.max)
        
        -- Draw UPGRADE button to the right of progression bar
        local upgrade_button_x = hotbar_x + tiers_width + 10
        local upgrade_button_y = tiers_y
        local upgrade_button_width = 100
        local upgrade_button_height = tiers_height
        self:draw_upgrade_button(upgrade_button_x, upgrade_button_y, 
                                upgrade_button_width, upgrade_button_height)
        
        -- Draw crafting UI to the right of inventory
        local craft_x = hotbar_x + hotbar_width + padding + 10
        local craft_y = hotbar_y
        local craft_size = 200
        CraftUI.draw(craft_x, craft_y, craft_size)
    end

    -- Selected item name below inventory
    local name_y = hotbar_y + total_height + 5
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
            love.graphics.print(text, hotbar_x, name_y)
        end
    end

    Love.draw(self)
end

-- Draw inventory slots (used for hotbar and backpack)
-- @param show_selection: if true, highlight the selected slot (for hotbar)
function Interface.draw_inventory_slots(self, inventory, start_x, start_y, slot_size, slots_per_row, show_selection)
    for i = 1, inventory.size do
        local col = (i - 1) % slots_per_row
        local row = math.floor((i - 1) / slots_per_row)
        local x = start_x + col * slot_size
        local y = start_y + row * slot_size

        -- Slot background
        love.graphics.setColor(0, 0, 0, 0.33)
        love.graphics.rectangle("fill", x, y, slot_size - 2, slot_size - 2)

        -- Slot border
        if show_selection and i == inventory.selected_slot then
            love.graphics.setColor(1, 1, 0, 0.5) -- Yellow for selected
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        end
        love.graphics.rectangle("line", x, y, slot_size - 4, slot_size - 4)

        -- Item in slot
        local slot = inventory:get_slot(i)
        if slot then
            self:draw_slot_item(slot, x, y, slot_size)
        end
    end
end

-- Draw a single slot item
function Interface.draw_slot_item(self, slot, x, y, slot_size)
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
        love.graphics.rectangle("fill", x + 8, y + 8, slot_size - 20, slot_size - 20)

        -- Draw count
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(tostring(slot.count), x + slot_size / 4, y + slot_size - 20 - 10)
    end
end

-- Draw cursor highlight for block under cursor
function Interface.draw_cursor_highlight(self, camera_x, camera_y, player_z)
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

-- Draw the UPGRADE button
function Interface.draw_upgrade_button(self, x, y, width, height)
    local mouse_x, mouse_y = love.mouse.getPosition()
    local is_hovered = mouse_x >= x and mouse_x <= x + width and
                       mouse_y >= y and mouse_y <= y + height
    
    -- Can upgrade if not at max tier
    local can_upgrade = G.player:get_omnitool_tier() < G.player.omnitool.max
    
    -- Button background
    if not can_upgrade then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    elseif is_hovered then
        love.graphics.setColor(0.6, 0.4, 0.2, 0.8)
    else
        love.graphics.setColor(0.4, 0.3, 0.1, 0.8)
    end
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Button border
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Button text
    love.graphics.setColor(1, 1, 1, 1)
    local button_text = can_upgrade and "UPGRADE" or "MAX TIER"
    local text_width = love.graphics.getFont():getWidth(button_text)
    local text_height = love.graphics.getFont():getHeight()
    love.graphics.print(button_text, x + width / 2 - text_width / 2, y + height / 2 - text_height / 2)
end

-- Check if upgrade button is clicked
-- Returns true if clicked and upgrade was performed
function Interface.is_upgrade_button_clicked(self, x, y, width, height, mouse_x, mouse_y)
    local is_clicked = mouse_x >= x and mouse_x <= x + width and
                       mouse_y >= y and mouse_y <= y + height
    
    if is_clicked and G.player:get_omnitool_tier() < G.player.omnitool.max then
        G.player:upgrade(1)
        return true
    end
    
    return false
end

-- Handle mouse clicks for UI elements
function Interface.mousepressed(self, x, y, button)
    if button ~= 1 then return end  -- Only handle left click
    
    local inventory_open = G.player.inventory_open
    if not inventory_open then return end
    
    -- Check upgrade button click
    local slot_size = BLOCK_SIZE * 2
    local hotbar_x = 10
    local hotbar_y = 10
    local hotbar_width = G.player.hotbar.size * slot_size
    local hotbar_height = slot_size
    local total_height = hotbar_height + (3 * slot_size)
    
    local tiers_y = hotbar_y + total_height + 30
    local tiers_width = hotbar_width
    local tiers_height = 40
    
    local upgrade_button_x = hotbar_x + tiers_width + 10
    local upgrade_button_y = tiers_y
    local upgrade_button_width = 100
    local upgrade_button_height = tiers_height
    
    if self:is_upgrade_button_clicked(upgrade_button_x, upgrade_button_y, 
                                      upgrade_button_width, upgrade_button_height, x, y) then
        Log.info("Interface", "Upgrade button clicked")
        return true
    end
    
    return false
end

return Interface
