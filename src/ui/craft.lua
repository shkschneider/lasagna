-- Crafting UI
-- Age upgrade crafting interface with material requirements

local Recipes = require "data.recipes"
local Tick = require "src.game.tick"
local Registry = require "src.registries"
local Log = require "libs.log"

local CraftUI = {
    can_craft_cache = false,
    current_recipe = nil,
}

-- Initialize craft UI with tick throttler for performance
function CraftUI.init()
    -- Check crafting button state every 10 ticks (1 second)
    CraftUI.check_tick = Tick.new(10, function()
        CraftUI.update_can_craft()
    end)
end

-- Update crafting state (called every 10 ticks)
function CraftUI.update_can_craft()
    if not G.player then
        CraftUI.can_craft_cache = false
        return
    end
    
    local current_tier = G.player:get_omnitool_tier()
    local target_age = current_tier + 1
    
    -- Get recipe for next age
    local recipe = Recipes.get_age_recipe(target_age)
    CraftUI.current_recipe = recipe
    
    if not recipe then
        CraftUI.can_craft_cache = false
        return
    end
    
    -- Check if player has all required materials
    -- We need to check both hotbar and backpack
    local has_materials = true
    for _, input in ipairs(recipe.inputs) do
        local hotbar_count = G.player.hotbar:count(input.id, input.type)
        local backpack_count = G.player.backpack:count(input.id, input.type)
        local total_count = hotbar_count + backpack_count
        
        if total_count < input.count then
            has_materials = false
            break
        end
    end
    
    CraftUI.can_craft_cache = has_materials
end

-- Update function called from game loop
function CraftUI.update(dt)
    if not CraftUI.check_tick then
        CraftUI.init()
    end
    CraftUI.check_tick:update(dt)
end

-- Draw the crafting interface
-- @param x: X position
-- @param y: Y position
-- @param width: Width of the crafting area
-- @param height: Height of the crafting area
function CraftUI.draw(x, y, width, height)
    if not G.player then
        return  -- Don't draw if player not available
    end
    
    local padding = 5
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Border
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Age Upgrade", x + padding, y + padding)
    
    local current_tier = G.player:get_omnitool_tier()
    local target_age = current_tier + 1
    
    -- Show current and next age
    local Lore = require "data.lore"
    local ages = Lore.Ages
    local current_age = ages[current_tier]
    local next_age = ages[target_age]
    
    local info_y = y + padding + 20
    if current_age then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print("Current: " .. current_age.name, x + padding, info_y)
    end
    
    info_y = info_y + 15
    if next_age then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Next: " .. next_age.name, x + padding, info_y)
    else
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print("Max Age Reached!", x + padding, info_y)
    end
    
    -- Show required materials
    info_y = info_y + 25
    if CraftUI.current_recipe then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Required:", x + padding, info_y)
        info_y = info_y + 15
        
        for _, input in ipairs(CraftUI.current_recipe.inputs) do
            local proto = nil
            if input.type == "block" then
                proto = Registry.Blocks:get(input.id)
            elseif input.type == "item" then
                proto = Registry.Items:get(input.id)
            end
            
            if proto then
                local hotbar_count = G.player.hotbar:count(input.id, input.type)
                local backpack_count = G.player.backpack:count(input.id, input.type)
                local total_count = hotbar_count + backpack_count
                
                -- Color based on whether player has enough
                if total_count >= input.count then
                    love.graphics.setColor(0.4, 1, 0.4, 1)  -- Green
                else
                    love.graphics.setColor(1, 0.4, 0.4, 1)  -- Red
                end
                
                local text = string.format("  %s: %d/%d", proto.name, total_count, input.count)
                love.graphics.print(text, x + padding, info_y)
                info_y = info_y + 15
            end
        end
    end
    
    -- Craft button
    local button_width = width - padding * 2
    local button_height = 30
    local button_x = x + padding
    local button_y = y + height - button_height - padding
    
    -- Check if mouse is over button
    local mouse_x, mouse_y = love.mouse.getPosition()
    local is_hovered = mouse_x >= button_x and mouse_x <= button_x + button_width and
                       mouse_y >= button_y and mouse_y <= button_y + button_height
    
    -- Determine if button is enabled
    local is_enabled = CraftUI.can_craft_cache and next_age ~= nil
    
    -- Button colors based on state
    if not is_enabled then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    elseif is_hovered then
        love.graphics.setColor(0.4, 0.6, 0.4, 0.8)
    else
        love.graphics.setColor(0.2, 0.4, 0.2, 0.8)
    end
    love.graphics.rectangle("fill", button_x, button_y, button_width, button_height)
    
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", button_x, button_y, button_width, button_height)
    
    -- Button text
    if is_enabled then
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
    end
    local button_text = is_enabled and "UPGRADE AGE" or "NOT ENOUGH MATERIALS"
    local text_width = love.graphics.getFont():getWidth(button_text)
    love.graphics.print(button_text, button_x + button_width / 2 - text_width / 2, button_y + 8)
end

-- Check if craft button is clicked
-- @param x: X position of craft UI
-- @param y: Y position of craft UI
-- @param width: Width of the crafting area
-- @param height: Height of the crafting area
-- @param mouse_x: Mouse X position
-- @param mouse_y: Mouse Y position
-- @return true if button was clicked and crafting is possible
function CraftUI.is_craft_button_clicked(x, y, width, height, mouse_x, mouse_y)
    local padding = 5
    local button_width = width - padding * 2
    local button_height = 30
    local button_x = x + padding
    local button_y = y + height - button_height - padding
    
    local is_in_bounds = mouse_x >= button_x and mouse_x <= button_x + button_width and
                         mouse_y >= button_y and mouse_y <= button_y + button_height
    
    return is_in_bounds and CraftUI.can_craft_cache
end

-- Perform the crafting action
function CraftUI.craft()
    if not G.player or not CraftUI.can_craft_cache or not CraftUI.current_recipe then
        return false
    end
    
    -- Try to consume from hotbar first, then backpack
    -- Note: Inventory:give() removes items from storage (counterintuitive naming)
    local success = true
    for _, input in ipairs(CraftUI.current_recipe.inputs) do
        local remaining = input.count
        
        -- Consume from hotbar
        local hotbar_count = G.player.hotbar:count(input.id, input.type)
        if hotbar_count > 0 then
            local to_remove = math.min(remaining, hotbar_count)
            local Stack = require "src.entities.stack"
            local stack = Stack.new(input.id, to_remove, input.type)
            -- give() removes items from inventory (output operation)
            if not G.player.hotbar:give(stack) then
                success = false
                break
            end
            remaining = remaining - to_remove
        end
        
        -- Consume from backpack if needed
        if remaining > 0 then
            local Stack = require "src.entities.stack"
            local stack = Stack.new(input.id, remaining, input.type)
            -- give() removes items from inventory (output operation)
            if not G.player.backpack:give(stack) then
                success = false
                break
            end
        end
    end
    
    if success then
        -- Upgrade the omnitool
        G.player:upgrade(1)
        
        -- Force immediate update of craft state
        CraftUI.update_can_craft()
        
        Log.info("CraftUI", "Upgraded to age", G.player:get_omnitool_tier())
        return true
    end
    
    return false
end

return CraftUI

