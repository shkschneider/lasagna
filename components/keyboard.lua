-- KeyboardState component
-- Keyboard input state

local KeyboardComponent = {}

function KeyboardComponent.new()
    return {
        id = "keyboard",
        keys_down = {},
        keys_pressed = {},
    }
end

return KeyboardComponent
