-- Tier progression UI
-- Displays omnitool tier progression with age names

local Ages = require "data.lore.ages"

local TiersUI = {}

-- Draw the tier progression bar
-- @param x: X position
-- @param y: Y position
-- @param width: Width of the progress bar
-- @param height: Height of the progress bar
-- @param current_tier: Current omnitool tier (1-4)
-- @param max_tier: Maximum tier (usually 4)
function TiersUI.draw(x, y, width, height, current_tier, max_tier)
    -- Guard against invalid values
    if max_tier <= 0 then
        max_tier = 1
    end
    if current_tier < 1 then
        current_tier = 1
    end
    if current_tier > max_tier then
        current_tier = max_tier
    end
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Border
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- Progress bar fill (shows current progress)
    local progress = current_tier / max_tier
    love.graphics.setColor(0.2, 0.6, 0.8, 0.8)
    love.graphics.rectangle("fill", x + 2, y + 2, (width - 4) * progress, height - 4)
    
    -- Draw vertical white lines for each tier marker
    local segment_width = width / max_tier
    for i = 1, max_tier - 1 do
        local line_x = x + segment_width * i
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.line(line_x, y, line_x, y + height)
    end
    
    -- Draw age names centered in each segment
    local font_height = love.graphics.getFont():getHeight()
    for i = 1, max_tier do
        local age = Ages[i]
        if age then
            local segment_x = x + segment_width * (i - 1)
            local text_x = segment_x + segment_width / 2
            local text_y = y + height / 2 - font_height / 2
            
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
    
    -- Draw tier counter
    love.graphics.setColor(1, 1, 1, 1)
    local tier_text = string.format("Tier %d/%d", current_tier, max_tier)
    local tier_width = love.graphics.getFont():getWidth(tier_text)
    love.graphics.print(tier_text, x + width / 2 - tier_width / 2, y - 20)
end

return TiersUI
