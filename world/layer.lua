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

function Layer:draw(camera_x, block_size, screen_w, screen_h, alpha)
    alpha = alpha or 1
    
    -- Calculate visible columns
    local left_col = math.floor(camera_x / block_size)
    local right_col = math.ceil((camera_x + screen_w) / block_size) + 1
    
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(-camera_x, 0)
    
    -- Draw visible columns
    for col = left_col, right_col do
        local column = self.tiles[col]
        if column then
            for row = 1, Game.WORLD_HEIGHT do
                local proto = column[row]
                if proto ~= nil then
                    local px = (col - 1) * block_size
                    local py = (row - 1) * block_size
                    if type(proto.draw) == "function" then
                        love.graphics.setColor(1, 1, 1, alpha)
                        proto:draw(px, py, block_size)
                    elseif proto.color and love and love.graphics then
                        local c = proto.color
                        love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * alpha)
                        love.graphics.rectangle("fill", px, py, block_size, block_size)
                    end
                end
            end
        end
    end
    
    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

return Layer
