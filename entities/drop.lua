local Object = require("lib.object")
local Physics = require("world.physics")
local Gravity = require("entities.components.gravity")

local Drop = Object {}

function Drop:new(proto, px, py, z, count)
    assert(proto)
    self.proto = proto  -- The block/item prototype
    self.px = px        -- Position in world coordinates (blocks)
    self.py = py
    self.z = z          -- Layer
    self.count = count or 1
    self.width = 1    -- 0.5 * 2 to match 2x2 subdivision
    self.height = 1   -- 0.5 * 2 to match 2x2 subdivision
    self.vy = 0
    self.lifetime = 0   -- Tracks how long the item has existed
    self.max_lifetime = C.DESPAWN_TIME
    self.collection_range = C.BLOCK_SIZE / 4
    self.gravity = Gravity(self)
end

function Drop:update(dt, world, player)
    self.lifetime = self.lifetime + dt

    -- Check if should despawn
    if self.lifetime >= self.max_lifetime then
        return false  -- Signal to world that this entity should be removed
    end

    -- Apply gravity using component (unless being held)
    if not self.being_held then
        self.gravity:update(dt)
        
        -- Apply physics movement (handles collision detection properly)
        local dy = self.vy * dt
        Physics.move(self, 0, dy, world)
    end

    -- Check if player is nearby and can collect
    if player and player.z == self.z and player.inventory and player.inventory.belt then
        local dx = (player.px + player.width / 2) - (self.px + self.width / 2)
        local dy_to_player = (player.py + player.height / 2) - (self.py + self.height / 2)
        local distance = math.sqrt(dx * dx + dy_to_player * dy_to_player)

        if distance < self.collection_range then
            -- Try to add to player's belt inventory using the Inventory component's add method
            local leftover = player.inventory.belt:add(self.proto, self.count)

            if leftover < self.count then
                -- Successfully collected at least some items
                self.count = leftover
                if self.count <= 0 then
                    return false  -- Remove this entity
                end
            end
        end
    end

    return true  -- Keep this entity alive
end

function Drop:draw()
    -- Position is already in 1-indexed world coordinates
    -- Drawing needs to convert to screen pixels
    local cx = G.camera:get_x()
    local sx = (self.px - 1) * C.BLOCK_SIZE - cx
    local sy = (self.py - 1) * C.BLOCK_SIZE

    -- Draw the item as a smaller version of the block
    if self.proto and self.proto.color then
        local c = self.proto.color
        love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
        love.graphics.rectangle("fill", sx, sy, self.width * C.BLOCK_SIZE, self.height * C.BLOCK_SIZE, 2, 2)

        -- Draw a subtle outline
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line", sx, sy, self.width * C.BLOCK_SIZE, self.height * C.BLOCK_SIZE, 2, 2)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Drop
