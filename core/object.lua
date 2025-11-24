require "core"

-- Object is a "Love Object" with composition.
local Object = {}

-- Note: if any sub-object priority changes or sub-objects are modified (added/removed)
--       internal (sorted) cache should be invalidated
local function Object_refresh(self)
    self.__objects = nil
end

-- Note: sub-objects are not in array (indexed) in any object
--       that is because Object_call shall only be called once per frame
--       (and it allows to access sub-objects easily with object.subObject)
--       whereas anytime an object needs another, it would search for it in the array
--       which would happen many times per frame
-- Cost: O(1) vs O(N log N)
local function Object_call(self, name, ...)
    if not self.__objects then
        self.__objects = {}
        for id, object in pairs(self) do
            -- all tables are considered potential sub-objects
            if type(object) == "table" then
                table.insert(self.__objects, object)
            end
        end
        table.sort(self.__objects, function(a, b)
            return (a.priority or INFINITY) < (b.priority or INFINITY)
        end)
    end
    -- Profile: local start = love.timer.getTime()
    for _, object in ipairs(self.__objects) do
        local f = object[name]
        if type(f) == "function" then
            -- Pass parent entity as second parameter for component methods
            f(object, ...)
        end
    end
    -- Profile: print(string.format("%s %s: %fs", string.upper(name), self.id or "?", (love.timer.getTime() - start)))
end

-- Love bindings

function Object.load(self, ...)
    Object_call(self, "load", ...)
end

function Object.update(self, dt)
    assert(type(dt) == "number")
    -- Pass self (parent entity) to components for update
    Object_call(self, "update", dt, self)
end

function Object.draw(self)
    -- Pass self (parent entity) to components for draw
    Object_call(self, "draw", self)
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
    Object_call(self, "mousereleased", x, y, button)
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

-- Make an Object with = Object.new {...}
function Object.new(...)
    local object = {
        __type = Object.__type,
    }
    for key, value in pairs(...) do
        object[key] = value
    end
    -- love2d
    object.load = Object_load
    object.update = Object_update
    object.draw = Object_draw
    object.keypressed = Object_keypressed
    object.keyreleased = Object_keyreleased
    object.mousepressed = Object_mousepressed
    object.mousereleased = Object_mousereleased
    object.wheelmoved = Object_wheelmoved
    object.textinput = Object_textinput
    object.resize = Object_resize
    object.focus = Object_focus
    object.quit = Object_quit
    -- /love2d
    object.tostring = Object_tostring
    return object
end

return Object
