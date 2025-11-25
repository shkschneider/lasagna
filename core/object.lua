require "core"

local Love = require "core.love"

return function(...)
    local object = {
        load = Love.load,
        update = Love.update,
        draw = Love.draw,
        keypressed = Love.keypressed,
        keyreleased = Love.keyreleased,
        mousepressed = Love.mousepressed,
        mousereleased = Love.mousereleased,
        wheelmoved = Love.wheelmoved,
        textinput = Love.textinput,
        resize = Love.resize,
        focus = Love.focus,
        quit = Love.quit,
        tostring = Love.tostring,
    }
    for key, value in pairs(...) do
        object[key] = value
    end
    return object
end
