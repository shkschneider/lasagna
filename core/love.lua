require "core"

local Love = {}

local function Love_call(self, name, ...)
    if not self.__objects then
        self.__objects = {}
        for id, object in pairs(self) do
            -- all tables are considered potential sub-objects
            if type(object) == "table" then
                table.insert(self.__objects, object)
            end
        end
        table.sort(self.__objects, function(a, b)
            return (a.priority or math.inf) < (b.priority or math.inf)
        end)
    end
    -- Profile: local start = love.timer.getTime()
    for _, object in ipairs(self.__objects) do
        local f = object[name]
        if type(f) == "function" then
            if name == "load" and Log then
                Log.debug("Loading", string.upper(object.id))
            end
            -- Pass parent entity as second parameter for component methods
            f(object, ...)
        end
    end
    -- Profile: print(string.format("%s %s: %fs", string.upper(name), self.id or "?", (love.timer.getTime() - start)))
end

function Love.load(self, ...)
    Love_call(self, "load", ...)
end

function Love.update(self, dt)
    assert(type(dt) == "number")
    Love_call(self, "update", dt, self)
end

function Love.draw(self)
    Love_call(self, "draw", self)
end

function Love.keypressed(self, key)
    assert(type(key) == "string")
    Love_call(self, "keypressed", key)
end

function Love.keyreleased(self, key)
    assert(type(key) == "string")
    Love_call(self, "keyreleased", key)
end

function Love.mousepressed(self, x, y, button)
    assert(type(x) == "number")
    assert(type(y) == "number")
    assert(type(button) == "number")
    Love_call(self, "mousepressed", x, y, button)
end

function Love.mousereleased(self, x, y, button)
    assert(type(x) == "number")
    assert(type(y) == "number")
    assert(type(button) == "number")
    Love_call(self, "mousereleased", x, y, button)
end

function Love.mousemoved(self, x, y, dx, dy)
    assert(type(x) == "number")
    assert(type(y) == "number")
    assert(type(dx) == "number")
    assert(type(dy) == "number")
    Love_call(self, "mousemoved", x, y, dx, dy)
end

function Love.wheelmoved(self, x, y)
    assert(type(x) == "number")
    assert(type(y) == "number")
    Love_call(self, "wheelmoved", x, y)
end

function Love.textinput(self, text)
    assert(type(text) == "string")
    Love_call(self, "textinput", text)
end

function Love.resize(self, width, height)
    assert(type(width) == "number")
    assert(type(height) == "number")
    Love_call(self, "resize", width, height)
end

function Love.focus(self, focused)
    assert(type(focused) == "boolean")
    Love_call(self, "focus", focused)
end

function Love.quit(self)
    Love_call(self, "quit")
end

function Love.tostring(self)
    return table.tostring(self)
end

return Love
