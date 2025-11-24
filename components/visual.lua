-- Visual Component
-- Contains rendering properties

local Visual = {}

function Visual.new(color, width, height)
    return {
        color = color or {1, 1, 1, 1},
        width = width or 0,
        height = height or 0,
    }
end

return Visual
