-- KeyboardState component
-- Keyboard input state

local Keyboard = {}

function Keyboard.new()
    return {
        id = "keyboard",
        keys_down = {},
        keys_pressed = {},
    }
end

return Keyboard
