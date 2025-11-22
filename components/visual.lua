-- Visual component
-- Rendering information

local Visual = {}

function Visual.new(color, width, height)
    return {
        color = color or {1, 1, 1, 1},
        width = width or 16,
        height = height or 16,
    }
end

return Visual
