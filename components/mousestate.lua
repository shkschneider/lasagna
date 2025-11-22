-- MouseState component
-- Mouse input state

local MouseState = {}

function MouseState.new()
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

return MouseState
