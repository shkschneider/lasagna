local Love = require "core.love"
local Object = require "core.object"
local Registry = require "src.registries"

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
        local backpack_y = hotbar_y + slot_size  -- Start right below hotbar
        self:draw_inventory_slots(backpack, hotbar_x, backpack_y, slot_size, 9, false)
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

return Interface
