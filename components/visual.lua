-- Visual component
-- Rendering information

local Visual = {}

function Visual.new(color, width, height)
    local instance = {
        id = "visual",
        priority = 100,  -- Visuals render late
        color = color or { 1, 1, 1, 1 },
        width = width or 16,
        height = height or 32,
        enabled = true,  -- Allow toggling for debugging
    }
    
    -- Assign update and draw methods to instance
    instance.update = Visual.update
    instance.draw = Visual.draw
    
    return instance
end

-- Component update method
function Visual.update(self, dt)
    -- Visual component doesn't need to update
end

-- Component draw method - renders the visual representation
function Visual.draw(self, entity, camera_x, camera_y)
    if not self.enabled then return end
    
    -- Render if entity has a position
    if entity and entity.position then
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill",
            entity.position.x - (camera_x or 0) - self.width / 2,
            entity.position.y - (camera_y or 0) - self.height / 2,
            self.width,
            self.height)
    end
end

return Visual
