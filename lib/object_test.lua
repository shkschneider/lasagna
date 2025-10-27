-- Small unit test for lib/object.lua demonstrating instance creation and default-field behavior.
-- Run with: lua lasagna/tests/test_object.lua

local Object = require("lib.object")

local Dog = Object {
    load = function () end,
    update = function (dt) end,
    draw = function () end,
}
local puppy = Dog()
assert(type(puppy.load) == "function", "Object.load()")
assert(type(puppy.update) == "function", "Object.update(dt, ...)")
assert(type(puppy.draw) == "function", "Object.draw()")

-- Define a simple prototype with default fields and an init method that can override coords.
local Tile = Object {
    x = 1,
    y = 2,
    color = {1, 0, 0, 1},
    init = function(self, x, y)
        if x ~= nil then self.x = x end
        if y ~= nil then self.y = y end
    end,
}

-- Create an instance without args -> should use prototype defaults
local t1 = Tile()
assert(t1.x == 1, "t1.x expected 1")
assert(t1.y == 2, "t1.y expected 2")
-- color should be a shallow-copied value (in our implementation table reference is copied)
assert(t1.color == Tile.color, "t1.color should reference the same table as prototype")

-- Create an instance with args -> init should override defaults
local t2 = Tile(3, 4)
assert(t2.x == 3, "t2.x expected 3")
assert(t2.y == 4, "t2.y expected 4")

-- Instances should have independent scalar fields (shallow-copy made scalar fields instance-local)
t1.x = 10
assert(t2.x == 3, "t2.x should remain 3 after changing t1.x")
assert(Tile.x == 1, "prototype x should remain 1")

-- Table defaults are shallow-copied by reference: modifying a nested table affects prototype and other instances
t1.color[1] = 0.5
assert(Tile.color[1] == 0.5, "changing instance color should reflect on prototype (shared reference)")

print("OK: test_object passed")