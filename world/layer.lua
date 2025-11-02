local Object = require("lib.object")
local log = require("lib.log")
local noise = require("lib.noise")
local Blocks = require("world.blocks")

local Layer = Object {}

function Layer:new(z)
    self.z = z
    self.tiles = {}
    self.heights = {}
    self.dirt_limit = {}
    self.stone_limit = {}
end

function Layer:update(dt) end

-- Generate terrain for a specific column
function Layer:generate_column(x, freq, base, amp)
    -- Skip if already generated
    if self.tiles[x] then return end

    local n = noise.perlin1d(x * freq + (self.z * 100))
    local top = math.max(1, math.min(C.WORLD_HEIGHT - 1, math.floor(base + amp * n)))
    local dirt_lim = math.min(C.WORLD_HEIGHT, top + C.DIRT_THICKNESS)
    local stone_lim = math.min(C.WORLD_HEIGHT, top + C.DIRT_THICKNESS + C.STONE_THICKNESS)

    self.heights[x] = top
    self.dirt_limit[x] = dirt_lim
    self.stone_limit[x] = stone_lim

    self.tiles[x] = {}
    for y = 1, C.WORLD_HEIGHT do
        local proto = nil
        if y == top then
            proto = Blocks and Blocks.grass
        elseif y > top and y <= dirt_lim then
            proto = Blocks and Blocks.dirt
        elseif y > dirt_lim and y <= stone_lim then
            proto = Blocks and Blocks.stone
        else
            proto = nil
        end
        self.tiles[x][y] = proto
    end
end

-- Generate terrain for a range of x coordinates
function Layer:generate_terrain_range(x_start, x_end, freq, base, amp)
    for x = x_start, x_end do
        self:generate_column(x, freq, base, amp)
    end
end

function Layer:draw()
    local alpha = 1
    local player = G:player()
    if player and type(player.z) == "number" and self.z < player.z then
        local depth = player.z - self.z
        alpha = 1 - 0.25 * depth
        if alpha < 0 then alpha = 0 end
    end

    -- Calculate visible columns
    local left_col = math.floor(G.cx / C.BLOCK_SIZE)
    local right_col = math.ceil((G.cx + G.width) / C.BLOCK_SIZE) + 1

    -- Draw directly without canvas to avoid shaky rendering
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(-G.cx, 0)

    -- Draw visible columns
    for col = left_col, right_col do
        local column = self.tiles[col]
        if column then
            for row = 1, C.WORLD_HEIGHT do
                local proto = column[row]
                if proto ~= nil then
                    local px = (col - 1) * C.BLOCK_SIZE
                    local py = (row - 1) * C.BLOCK_SIZE
                    if type(proto.draw) == "function" then
                        love.graphics.setColor(1, 1, 1, alpha)
                        proto:draw(px, py, C.BLOCK_SIZE)
                    elseif proto.color and love and love.graphics then
                        local c = proto.color
                        love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * alpha)
                        love.graphics.rectangle("fill", px, py, C.BLOCK_SIZE, C.BLOCK_SIZE)
                    end
                end
            end
        end
    end

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

return Layer
