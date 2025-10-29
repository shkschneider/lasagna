local Object = {}

function Object.new(prototype, ...)
    if type(prototype) ~= "table" then
        error("Object.new: prototype must be a table", 2)
    end
    -- instance delegates to prototype for methods/defaults
    local instance = setmetatable({}, { __index = prototype })
    -- call instance-level constructor method if present
    if type(instance.new) == "function" then
        instance:new(...)
    end
    return instance
end

setmetatable(Object, {
    __call = function(_, prototype)
        prototype = prototype or {}
        if type(prototype.new) ~= "function" then
            prototype.new = function(self, ...)
                return Object.new(self, ...)
            end
        end
        return setmetatable(prototype, {
            __call = function(instance, ...)
                return Object.new(instance, ...)
            end,
        })
    end,
})

return Object