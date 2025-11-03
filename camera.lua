local Object = require("lib.object")

local Camera = Object {
    x = 0,
    y = 0,
}

function Camera:new()
    self.x = 0
    self.y = 0
end

function Camera:follow(target_x, target_y, screen_width, screen_height)
    -- Center camera on target
    self.x = target_x - screen_width / 2
    self.y = target_y - screen_height / 2
end

function Camera:get_position()
    return self.x, self.y
end

function Camera:get_x()
    return self.x
end

function Camera:get_y()
    return self.y
end

function Camera:set_position(x, y)
    self.x = x
    self.y = y
end

return Camera
