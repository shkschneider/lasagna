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

        -- Apply sand-like spreading physics when grounded
        Physics.apply_spreading(self, world, dt)

        -- Snap to block grid when grounded (no animation)
        if self.vy == 0 then
            self.px = math.floor(self.px + 0.5)
            self.py = math.floor(self.py + 0.5)
            
            -- When grounded, check for similar drops below to merge with
            for _, other in ipairs(world.entities) do
                if other ~= self and other.proto and other.proto == self.proto and other.z == self.z then
                    -- Check if other drop is directly below (1 block)
                    local dx = math.abs(other.px - self.px)
                    local dy = other.py - self.py
                    
                    -- Merge if drop is at same horizontal position and exactly 1 block below
                    if dx < 0.5 and dy >= 0.5 and dy <= 1.5 then
                        -- Merge this drop into the one below
                        other.count = other.count + self.count
                        return false  -- Remove this drop after merging
                    end
                end
            end
        end
    end

    -- Check if player is nearby and can collect
    if player and player.z == self.z and player.inventory and player.inventory.belt then
        local dx = (player.px + player.width / 2) - (self.px + self.width / 2)
        local dy_to_player = (player.py + player.height / 2) - (self.py + self.height / 2)
        local distance = math.sqrt(dx * dx + dy_to_player * dy_to_player)

        if distance < self.collection_range then
            -- New pickup priority:
            -- 1. Try to add to existing non-full stacks in hotbar (belt)
            -- 2. Try to add to storage (inventory)
            -- 3. If storage is full, try to fill empty hotbar slots
            
            local leftover = self.count
            
            -- Step 1: Try to stack with existing items in hotbar
            local belt = player.inventory.belt
            local max_stack = math.min(self.proto.max_stack or C.MAX_STACK, C.MAX_STACK)
            for i = 1, belt.slots do
                local slot = belt.items[i]
                if slot and slot.proto == self.proto then
                    local space = max_stack - slot.count
                    if space > 0 then
                        local to_add = math.min(space, leftover)
                        slot.count = slot.count + to_add
                        leftover = leftover - to_add
                        if leftover <= 0 then
                            return false  -- All items collected
                        end
                    end
                end
            end
            
            -- Step 2: Try to add to storage
            if leftover > 0 then
                leftover = player.inventory.storage:add(self.proto, leftover)
            end
            
            -- Step 3: If storage is full, try to add to empty hotbar slots
            if leftover > 0 then
                for i = 1, belt.slots do
                    if not belt.items[i] then
                        local to_add = math.min(max_stack, leftover)
                        belt.items[i] = {
                            proto = self.proto,
                            count = to_add,
                            data = {}
                        }
                        leftover = leftover - to_add
                        if leftover <= 0 then
                            return false  -- All items collected
                        end
                    end
                end
            end
            
            -- Update the drop with whatever is left
            if leftover < self.count then
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
    local cy = G.camera:get_y()
    local sx = (self.px - 1) * C.BLOCK_SIZE - cx
    local sy = (self.py - 1) * C.BLOCK_SIZE - cy

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
