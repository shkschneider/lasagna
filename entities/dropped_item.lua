local Object = require("lib.object")

local DroppedItem = Object {}

function DroppedItem:new(proto, px, py, z, count)
    self.proto = proto  -- The block/item prototype
    self.px = px        -- Position in world coordinates (blocks)
    self.py = py
    self.z = z          -- Layer
    self.count = count or 1
    self.width = 0.5    -- Smaller than a full block
    self.height = 0.5
    self.vx = 0
    self.vy = 0
    self.lifetime = 0   -- Tracks how long the item has existed
    self.max_lifetime = 60  -- Despawn after 60 seconds
    self.collection_range = 1.0  -- Distance at which player can collect
end

function DroppedItem:update(dt, world, player)
    self.lifetime = self.lifetime + dt
    
    -- Check if should despawn
    if self.lifetime >= self.max_lifetime then
        return false  -- Signal to world that this entity should be removed
    end
    
    -- Simple physics - just apply gravity
    self.vy = self.vy + C.GRAVITY * dt
    local dy = self.vy * dt
    
    -- Simple ground check - stop falling when hitting solid ground
    local below_row = math.floor(self.py + self.height + dy)
    local left_col = math.floor(self.px)
    local right_col = math.floor(self.px + self.width)
    
    local hit_ground = false
    for col = left_col, right_col do
        if world:is_solid(self.z, col, below_row) then
            hit_ground = true
            break
        end
    end
    
    if hit_ground then
        self.vy = 0
        -- Snap to ground
        self.py = math.floor(self.py + self.height) - self.height
    else
        self.py = self.py + dy
    end
    
    -- Check if player is nearby and can collect
    if player and player.z == self.z then
        local dx = (player.px + player.width / 2) - (self.px + self.width / 2)
        local dy_to_player = (player.py + player.height / 2) - (self.py + self.height / 2)
        local distance = math.sqrt(dx * dx + dy_to_player * dy_to_player)
        
        if distance < self.collection_range then
            -- Try to add to player's inventory
            local leftover = 0
            if player.inventory and player.inventory.items then
                -- Use the new inventory component if available
                local Inventory = require("entities.components.inventory")
                local inv = Inventory(player, { slots = player.inventory.slots })
                inv.items = player.inventory.items
                inv.selected = player.inventory.selected
                leftover = inv:add(self.proto, self.count)
                player.inventory.items = inv.items
            else
                -- Fallback: just try to add directly
                leftover = self.count
            end
            
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

function DroppedItem:draw()
    local sx = (self.px - 1) * C.BLOCK_SIZE - G.cx
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

return DroppedItem
