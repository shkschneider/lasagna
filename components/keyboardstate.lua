-- KeyboardState component
-- Keyboard input state

local KeyboardState = {}

function KeyboardState.new()
    return {
        id = "keyboard",
        keys_down = {},
        keys_pressed = {},
    }
end

return KeyboardState
