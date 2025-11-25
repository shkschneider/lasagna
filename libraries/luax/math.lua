-- Lua eXtended -- math

if not math.eps then math.eps = 1 / 1000 end
if not math.inf then math.inf = math.huge or (9 ^ 9) end -- 387_420_489

-- Note: I prefer the value to be in-between
local function math_clamp(low, n, high)
    return math.min(math.max(n, low), high)
end
if not math.clamp then math.clamp = math_clamp end

local function math_lerp(from, to, progress)
    return from * (1 - progress) + to * progress
end
if not math.lerp then math.lerp = math_lerp end

local function math_sign(self)
    -- or return self < 0 and -1 or 1
    return (self > 0 and 1) or (self < 0 and -1) or 0
end
if not math.sign then math.sign = math_sign end

local function math_round(self)
    if self < 0 then
        return math.ceil(self - 0.5)
    else
        return math.floor(self + 0.5)
    end
end
if not math.round then math.round = math_round end
