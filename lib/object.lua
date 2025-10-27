--[[
    local Animal = Object {}
    local dog = Animal()
    local cat = Animal()
--]]

local Object = {}

function Object:init(...) end

function Object:extend(data)
    data = data or {}
    setmetatable(data, {
        __call = function(self, ...)
            local instance = setmetatable({}, { __index = data })
            for k, v in pairs(data) do
                if type(v) ~= "function" then
                    if not (type(k) == "string" and k:match("^__")) then
                        instance[k] = v
                    end
                end
            end
            if type(instance.init) == "function" then
                instance:init(...)
            end
            return instance
        end,
    })
    return data
end

setmetatable(Object, {
    __call = function(self, data)
        return self:extend(data)
    end,
})

return Object