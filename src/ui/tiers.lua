-- Tier progression UI
-- Displays omnitool tier progression with age names

local Ages = require "data.lore.ages"

local TiersUI = {}

-- Draw the tier progression bar
-- @param x: X position
-- @param y: Y position
-- @param width: Width of the progress bar
-- @param height: Height of the progress bar
-- @param current_tier: Current omnitool tier (0-4)
-- @param max_tier: Maximum tier (usually 4)
function TiersUI.draw(x, y, width, height, current_tier, max_tier)
    -- Guard against invalid values
    if max_tier <= 0 then
        max_tier = 1
    end
    if current_tier < 0 then
        current_tier = 0
    end
    if current_tier > max_tier then
        current_tier = max_tier
    end
    
    -- Draw tier counter above the line
    love.graphics.setColor(1, 1, 1, 1)
    local tier_text = string.format("Tier %d/%d", current_tier, max_tier)
    local tier_width = love.graphics.getFont():getWidth(tier_text)
    love.graphics.print(tier_text, x + width / 2 - tier_width / 2, y - 20)
    
    -- Calculate vertical center for the line
    local line_y = y + height / 2
    
    -- Draw main horizontal line
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(x, line_y, x + width, line_y)
    
    -- Draw progress line (shows current progress)
    local num_tiers = max_tier + 1  -- Add 1 to include tier 0
    local progress = (current_tier + 1) / num_tiers
    love.graphics.setColor(0.2, 0.6, 0.8, 1)
    love.graphics.setLineWidth(3)
    love.graphics.line(x, line_y, x + width * progress, line_y)
    
    -- Draw vertical tick marks in-between ages
    local segment_width = width / num_tiers
    local tick_height = 15
    -- Draw tick marks between tiers (not at start/end)
    for i = 1, num_tiers - 1 do
        local tick_x = x + segment_width * i
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.line(tick_x, line_y - tick_height / 2, tick_x, line_y + tick_height / 2)
    end
    
    -- Draw age names below each segment
    local font_height = love.graphics.getFont():getHeight()
    for i = 0, max_tier do
        local age = Ages[i]
        if age then
            local segment_x = x + segment_width * i
            local text_x = segment_x + segment_width / 2
            local text_y = line_y + tick_height / 2 + 5
            
            -- Highlight current tier
            if i == current_tier then
                love.graphics.setColor(1, 1, 1, 1)
            else
                love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
            end
            
            -- Draw age name (shortened to fit)
            local age_text = age.name:gsub(" Age", "")
            local text_width = love.graphics.getFont():getWidth(age_text)
            love.graphics.print(age_text, text_x - text_width / 2, text_y)
        end
    end
end

return TiersUI
