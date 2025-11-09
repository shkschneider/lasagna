local Object = require("lib.object")

local Item = Object {}

function Item:new(name, color)
    if type(name) ~= "string" then error("Item:new: name must be a string", 2) end
    self.name = name
    self.color = color
    self.max_stack = 1  -- Default stack size for tools/items
end

local Items = {
    gun = Item("gun", {0.2, 0.2, 0.2, 1.0}),  -- Dark grey gun
    rocket_launcher = Item("rocket_launcher", {0.4, 0.2, 0.1, 1.0}),  -- Dark orange/brown rocket launcher
}

return Items
