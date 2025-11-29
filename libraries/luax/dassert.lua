local _assert = assert

dassert = setmetatable({
    DEBUG = false,
}, {
    __call = function(self, condition, message, ...)
        if not self.DEBUG then return end
        if not condition then
            error(message and string.format(message, ...) or "assertion failed", 2)
        end
    end,
})

-- assert = require("dassert")
return dassert
