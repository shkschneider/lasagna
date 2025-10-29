--[[
    local Animal = Object {}
    local dog = Animal()
    local cat = Animal()
--]]

local Object = {}

function Object:load() end
function Object:update(dt) end
function Object:draw() end

setmetatable(Object, {
    __call = function(self, data)
        return setmetatable(data or {}, {
            __call = function(_, ...)
                local instance = setmetatable({}, { __index = data })
                for k, v in pairs(data) do
                    if type(v) ~= "function" then
                        if not (type(k) == "string" and k:match("^__")) then
                            instance[k] = v
                        end
                    end
                end
                if type(instance.load) == "function" then
                    instance:load(...)
                end
                return instance
            end,
        })
    end,
})

return Object