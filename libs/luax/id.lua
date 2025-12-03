-- Lua eXtended -- id

if not id then
    function id()
        local template = 'xxxxxxx'
        return string.gsub(template, 'x', function (c)
            return string.format('%x', math.random(0, 0xf))
        end)
    end
end

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
