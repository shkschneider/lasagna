-- MouseState component
-- Mouse input state

local Mouse = {}

function Mouse.new()
    return {
        id = "mouse",
        x = 0,
        y = 0,
        buttons = {},
        tostring = function(self)
            return string.format("%d,%d", self.x, self.y)
        end
    }
end

return Mouse
