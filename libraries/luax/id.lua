-- Lua eXtended -- id

-- good-enough identifiers
if not uuid then
    function uuid()
        local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
        return string.gsub(template, '[xy]', function (c)
            local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
            return string.format('%x', v)
        end)
    end
end
-- Benchmark:
-- local t1 = love.timer.getTime()
-- for n = 1, 420000 do
--     uuid()
-- end
-- print(string.format("%f", love.timer.getTime() - t1))
