-- local rng = require(...)
-- rng(rng())
math.random = (love and love.math.random) or math.random

return function(seed)
    if seed then
        if love then
            love.math.setRandomSeed(seed)
        else
            math.randomseed(seed)
        end
        return seed
    else
        local base = tonumber(tostring(os.time()):reverse())
        local mul = tonumber(tostring(os.clock()):reverse())
        return (math.floor(base * mul) % 0x80000000) -- 32bit
    end
end
