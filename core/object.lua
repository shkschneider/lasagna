require "lib"

local Object = {}

local function Object_load(self)
    for id, object in pairs(self) do
        if type(object) == "table" and object.load then
            object:load()
        end
    end
end

local function Object_update(self, dt)
    for id, object in pairs(self) do
        if type(object) == "table" and object.update then
            object:update(dt)
        end
    end
end

local function Object_draw(self)
    for id, object in pairs(self) do
        if type(object) == "table" and object.draw then
            object:draw()
        end
    end
end

local function Object_tostring(self)
    return table.tostring(self)
end

return function(...)
    local object = {}
    for key, value in pairs(...) do
        object[key] = value
    end
    object.load = Object_load
    object.update = Object_update
    object.draw = Object_draw
    object.tostring = Object_tostring
    return object
end
