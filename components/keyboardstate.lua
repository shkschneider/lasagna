-- KeyboardState component
-- Keyboard input state

local KeyboardState = {}

function KeyboardState.new()
    return {
        keys_down = {},
        keys_pressed = {},
    }
end

return KeyboardState
