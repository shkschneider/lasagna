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
    if player and player.z == self.z and player.inventory then
        local dx = (player.px + player.width / 2) - (self.px + self.width / 2)
        local dy_to_player = (player.py + player.height / 2) - (self.py + self.height / 2)
        local distance = math.sqrt(dx * dx + dy_to_player * dy_to_player)
        
        if distance < self.collection_range then
            -- Try to add to player's inventory directly
            local leftover = self.count
            if player.inventory.items then
                -- Try to stack with existing items first
                local max_stack = self.proto.max_stack or C.MAX_STACK
                for i = 1, player.inventory.slots do
                    local slot = player.inventory.items[i]
                    if slot and slot.proto == self.proto then
                        local space = max_stack - slot.count
                        if space > 0 then
                            local to_add = math.min(space, leftover)
                            slot.count = slot.count + to_add
                            leftover = leftover - to_add
                            if leftover <= 0 then break end
                        end
                    end
                end
                
                -- If still have items left, try to find empty slots
                if leftover > 0 then
                    for i = 1, player.inventory.slots do
                        if not player.inventory.items[i] then
                            local to_add = math.min(max_stack, leftover)
                            player.inventory.items[i] = {
                                proto = self.proto,
                                count = to_add,
                                data = {}
                            }
                            leftover = leftover - to_add
                            if leftover <= 0 then break end
                        end
                    end
                end
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
