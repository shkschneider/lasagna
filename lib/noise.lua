-- Perlin noise implementation (1D) with initialization
-- Exposes:
--   noise1d.init(seed)    -- initialize permutation table (optional, but recommended)
--   noise1d.perlin1d(x)   -- perlin with local defaults OCTAVES and PERSISTENCE

local noise1d = {}

local p = {}

-- Local default constants for perlin parameters (renamed per request)
local OCTAVES = 4
local PERSISTENCE = 0.5

local function fade(t) return t * t * t * (t * (t * 6 - 15) + 10) end
local function lerp(t, a, b) return a + t * (b - a) end
local function grad(hash, x) return (hash % 2 == 0 and x or -x) end

local function noise(x)
    local xi = math.floor(x) % 256
    local xf = x - math.floor(x)
    local u = fade(xf)
    local a = p[xi + 1]
    local b = p[xi + 2]
    return lerp(u, grad(a, xf), grad(b, xf - 1)) * 2
end

function noise1d.init(seed)
    -- Populate permutation table using the provided seed.
    if seed then
        math.randomseed(seed)
        -- discard first few values for better distribution on some Lua implementations
        math.random(); math.random(); math.random()
    end
    for i = 1, 256 do
        p[i] = math.random(0, 255)
        p[i + 256] = p[i]
    end
end

-- perlin1d now takes only x and uses local OCTAVES and PERSISTENCE
function noise1d.perlin1d(x)
    local total, amp, freq, max_val = 0, 1, 1, 0
    for i = 1, OCTAVES do
        total = total + noise(x * freq) * amp
        max_val = max_val + amp
        amp = amp * PERSISTENCE
        freq = freq * 2
    end
    if max_val == 0 then return 0 end
    return total / max_val
end

-- If not initialized, initialize with a time-based seed (best-effort)
if #p == 0 then
    noise1d.init(os.time() + math.floor((love and love.timer.getTime()) or 0))
end

return noise1d