random = random or love.math.random

EPSILON = 1 / 1000 -- 0.001
INFINITY = math.huge -- was 9 ^ 9 -- 387_420_489

function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function table.tostring(self)
    local s = "{"
    for k, v in pairs(self) do
        if #s > 1 then
            s = s .. ","
        end
        s = s .. tostring(k) .. "="
        if type(v) == "function" then
            s = s .. "()"
        elseif type(v) == "table" then
            s = s .. "{}"
        else
            s = s .. tostring(v)
        end
    end
    return s .. "}"
end

function math.clamp(low, n, high)
    return math.min(math.max(n, low), high)
end

function DEBUG(level)
    level = (level or 1) + 1 -- +1 to account for this function's own stack frame
    local info = debug.getinfo(level, "nSl")
    local fname = info.short_src or "?"
    local line = info.currentline or "?"
    local method = info.name or "?"
    print(string.format("%s:%d %s()", fname, line, method))
end
