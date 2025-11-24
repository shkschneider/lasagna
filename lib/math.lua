EPSILON = 1 / 1000 -- 0.001
INFINITY = math.huge -- was 9 ^ 9 -- 387_420_489

function math.clamp(low, n, high)
    return math.min(math.max(n, low), high)
end
