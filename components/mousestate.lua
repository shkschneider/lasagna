-- MouseState component
-- Mouse input state

local MouseState = {}

function MouseState.new()
    return {
        id = "mouse",
        x = 0,
        y = 0,
        buttons = {},
    }
end

return MouseState
