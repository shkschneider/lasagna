local Object = require("lib.object")
local log = require("lib.log")

local Layer = Object {}

function Layer:new(z)
    self.z = z
    self.tiles = {}
    self.heights = {}
    self.dirt_limit = {}
    self.stone_limit = {}
    self.canvas = nil
end

function Layer:update(dt) end

function Layer:draw(cx)
    local alpha = 1
    local player = G:player()
    if player and type(player.z) == "number" and self.z < player.z then
        local depth = player.z - self.z
        alpha = 1 - 0.25 * depth
        if alpha < 0 then alpha = 0 end
    end

    -- Calculate visible columns
    local left_col = math.floor(cx / C.BLOCK_SIZE)
    local right_col = math.ceil((cx + G.width) / C.BLOCK_SIZE) + 1

    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(-cx, 0)

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

-- TODO Layer:generate_column()
-- TODO Layer:generate_terrain_range()

return Layer
