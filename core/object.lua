require "lib"

local Object = {
    __type = "Object",
}

function Object.is(self)
    return self.__type and self.__type == Object.__type
end

local function Object_call(object, name, ...)
    for id, object in pairs(object) do
        if type(object) == "table" and object[name] then
            local f = object[name]
            f(object, ...)
        end
    end
end

function Object.load(self)
    Object_call(self, "load")
end

function Object.update(self, dt)
    assert(type(dt) == "number")
    Object_call(self, "update", dt)
end

function Object.draw(self)
    Object_call(self, "draw")
end

function Object.keypressed(self, key)
    assert(type(key) == "string")
    Object_call(self, "keypressed", key)
end

function Object.keyreleased(self, key)
    assert(type(key) == "string")
    Object_call(self, "keyreleased", key)
end

function Object.mousepressed(self, x, y, button)
    assert(type(x) == "number")
    assert(type(y) == "number")
    assert(type(button) == "number")
    Object_call(self, "mousepressed", x, y, button)
end

function Object.mousereleased(self, x, y, button)
    assert(type(x) == "number")
    assert(type(y) == "number")
    assert(type(button) == "number")
    Object_call("mousereleased", x, y, button)
end

function Object.mousemoved(self, x, y, dx, dy)
    assert(type(x) == "number")
    assert(type(y) == "number")
    assert(type(dx) == "number")
    assert(type(dy) == "number")
    Object_call(self, "mousemoved", x, y, dx, dy)
end

function Object.wheelmoved(self, x, y)
    assert(type(x) == "number")
    assert(type(y) == "number")
    Object_call(self, "wheelmoved", x, y)
end

function Object.textinput(self, text)
    assert(type(text) == "string")
    Object_call(self, "textinput", text)
end

function Object.resize(self, width, height)
    assert(type(width) == "number")
    assert(type(height) == "number")
    Object_call(self, "resize", width, height)
end

function Object.focus(self, focused)
    assert(type(focused) == "boolean")
    Object_call(self, "focus", focused)
end

function Object.quit(self)
    Object_call(self, "quit")
end

function Object.tostring(self)
    return table.tostring(self)
end

function Object.new(...)
    local object = {
        __type = Object.__type,
    }
    for key, value in pairs(...) do
        object[key] = value
    end
    object.load = Object_load
    object.update = Object_update
    object.draw = Object_draw
    object.tostring = Object_tostring
    return object
end

return Object
