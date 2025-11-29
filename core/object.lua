local Love = require "core.love"

return function(...)
    local object = {}
    for key, value in pairs(...) do
        object[key] = value
    end
    if type(object.init) == "function" then
        object:init()
    end
    return setmetatable(object, { __index = Love })
end
