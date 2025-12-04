-- tests/itemdrops.lua
-- CLI tests for src/entities/itemdrop.lua - tests pickup, despawn, and merging mechanics.
-- Run from repo root:
--   LUA_PATH="./?.lua;./?/init.lua;;" lua5.1 ./tests/itemdrops.lua

local function ok(msg)
    print("PASS: " .. msg)
end
local function fail(msg)
    print("FAIL: " .. msg)
    os.exit(1)
end
local function expect(cond, msg)
    if cond then ok(msg) else fail(msg) end
end

-- Setup minimal mocks for LÖVE environment and global constants
BLOCK_SIZE = 16
LAYER_DEFAULT = 0
STACK_SIZE = 64

-- Mock id() function from luax
function id()
    local template = 'xxxxxxx'
    return string.gsub(template, 'x', function (c)
        return string.format('%x', math.random(0, 0xf))
    end)
end

-- Mock the core.object module
package.loaded["core.object"] = function(tbl) return tbl end

-- Mock the core.love module
package.loaded["core.love"] = {
    load = function(self) end,
    update = function(self, dt) end,
}

-- Mock Vector
local Vector = {
    new = function(x, y, z)
        return {
            x = x or 0,
            y = y or 0,
            z = z or LAYER_DEFAULT,
        }
    end
}
package.loaded["src.game.vector"] = Vector

-- Mock Physics module
local Physics = {
    apply_gravity = function(vel, gravity, dt)
        vel.y = vel.y + gravity * dt
    end,
    is_on_ground = function(world, pos, width, height)
        -- For testing, return true if position is at y=0
        return pos.y >= 0
    end,
}
package.loaded["src.world.physics"] = Physics

-- Mock Stack module (simplified version for testing)
local Stack = {
    MAX_SIZE = 64,
    new = function(id, count, id_type)
        local stack = {
            item_id = nil,
            block_id = nil,
            count = count or 1,
        }
        if id_type == "item" then
            stack.item_id = id
        else
            stack.block_id = id
        end
        stack.count = math.max(0, math.min(stack.count, Stack.MAX_SIZE))
        return setmetatable(stack, { __index = Stack })
    end,
}
package.loaded["src.entities.stack"] = Stack

-- Mock global G object used by ItemDrop
G = {}

-- Mock world
G.world = {
    get_block_def = function(self, layer, col, row)
        -- For simplicity, return solid ground at row 0
        if row == 0 then
            return { solid = true }
        end
        return nil
    end,
}

-- Mock entities system
G.entities = {
    _drops = {},
    getByType = function(self, entity_type)
        if entity_type == "drop" then
            return self._drops
        end
        return {}
    end,
    add = function(self, entity)
        if entity.type == "drop" then
            table.insert(self._drops, entity)
        end
    end,
    clear = function(self)
        self._drops = {}
    end,
}

-- Mock player with inventory
G.player = {
    position = Vector.new(0, 0, 0),
    inventory = {},
    inventory_size = 0,
    add_to_inventory = function(self, block_id, count)
        -- Simple mock: track what was added
        table.insert(self.inventory, { block_id = block_id, count = count })
        self.inventory_size = self.inventory_size + count
        return true
    end,
    reset = function(self)
        self.inventory = {}
        self.inventory_size = 0
    end,
}

-- Load the ItemDrop module
local ItemDrop = require("src.entities.itemdrop")

print("=== ItemDrop Tests ===\n")

-- Test 1: Player Pickup Mechanics
print("-- Test 1: Player pickup mechanics")
do
    G.player:reset()
    G.entities:clear()
    
    -- Create an ItemDrop at player's position with no pickup delay
    local drop = ItemDrop.new(0, 0, 0, 1, 5, 300, 0)
    G.entities:add(drop)
    
    -- Initially, drop should not be dead
    expect(not drop.dead, "Drop is not dead initially")
    
    -- Position player at drop location
    G.player.position.x = 0
    G.player.position.y = 0
    G.player.position.z = 0
    
    -- Update drop (should trigger pickup)
    drop:update(0.016)
    
    -- Check that player picked up the item
    expect(#G.player.inventory == 1, "Player inventory has 1 entry after pickup")
    expect(G.player.inventory[1].block_id == 1, "Player picked up correct block_id")
    expect(G.player.inventory[1].count == 5, "Player picked up correct count")
    expect(drop.dead, "Drop is marked dead after pickup")
end

print("\n-- Test 2: Pickup delay prevents immediate pickup")
do
    G.player:reset()
    G.entities:clear()
    
    -- Create an ItemDrop with 1 second pickup delay at position with no initial velocity
    local drop = ItemDrop.new(0, 0, 0, 2, 3, 300, 1.0)
    drop.velocity.x = 0  -- Override random velocity
    drop.velocity.y = 0
    G.entities:add(drop)
    
    -- Position player at drop location
    G.player.position.x = 0
    G.player.position.y = 0
    G.player.position.z = 0
    
    -- Update drop (pickup should be blocked by delay)
    drop:update(0.016)
    
    expect(#G.player.inventory == 0, "Player inventory empty due to pickup delay")
    expect(not drop.dead, "Drop is not dead due to pickup delay")
    expect(drop.pickup_delay < 1.0, "Pickup delay decreased")
    
    -- Simulate enough time passing to expire pickup delay
    -- Keep player at drop location throughout
    for i = 1, 70 do
        if not drop.dead then
            drop.position.x = 0  -- Keep drop at player position
            drop.position.y = 0
            drop.velocity.x = 0
            drop.velocity.y = 0
            drop:update(0.016)
        end
    end
    
    -- Now pickup should succeed
    expect(drop.pickup_delay <= 0, "Pickup delay expired")
    expect(drop.dead, "Drop is marked dead after pickup delay expired")
    expect(#G.player.inventory == 1, "Player inventory has item after delay expired")
end

print("\n-- Test 3: Pickup requires same layer")
do
    G.player:reset()
    G.entities:clear()
    
    -- Create an ItemDrop on layer 1
    local drop = ItemDrop.new(0, 0, 1, 3, 2, 300, 0)
    G.entities:add(drop)
    
    -- Position player at same location but layer 0
    G.player.position.x = 0
    G.player.position.y = 0
    G.player.position.z = 0
    
    -- Update drop (pickup should fail due to layer mismatch)
    drop:update(0.016)
    
    expect(#G.player.inventory == 0, "Player inventory empty due to layer mismatch")
    expect(not drop.dead, "Drop is not dead due to layer mismatch")
    
    -- Move player to same layer
    G.player.position.z = 1
    drop:update(0.016)
    
    expect(drop.dead, "Drop is marked dead after player on same layer")
    expect(#G.player.inventory == 1, "Player inventory has item after layer match")
end

print("\n-- Test 4: Pickup range")
do
    G.player:reset()
    G.entities:clear()
    
    -- Create an ItemDrop far from player
    local drop = ItemDrop.new(100, 100, 0, 4, 1, 300, 0)
    G.entities:add(drop)
    
    -- Position player at origin
    G.player.position.x = 0
    G.player.position.y = 0
    G.player.position.z = 0
    
    -- Update drop (pickup should fail due to distance)
    drop:update(0.016)
    
    expect(#G.player.inventory == 0, "Player inventory empty due to distance")
    expect(not drop.dead, "Drop is not dead due to distance")
    
    -- Move player closer (within BLOCK_SIZE range = 16)
    G.player.position.x = 100
    G.player.position.y = 100
    drop:update(0.016)
    
    expect(drop.dead, "Drop is marked dead when player is close")
    expect(#G.player.inventory == 1, "Player inventory has item when close")
end

-- Test 5: Despawn Delay
print("\n-- Test 5: Despawn delay (lifetime)")
do
    G.player:reset()
    G.entities:clear()
    
    -- Create an ItemDrop with 1 second lifetime
    local drop = ItemDrop.new(0, 0, 0, 5, 1, 1.0, 0)
    G.entities:add(drop)
    
    -- Position player far away to prevent pickup
    G.player.position.x = 1000
    G.player.position.y = 1000
    G.player.position.z = 0
    
    expect(drop.lifetime == 1.0, "Initial lifetime is 1.0 seconds")
    expect(not drop.dead, "Drop is not dead initially")
    
    -- Update for 0.5 seconds
    for i = 1, 30 do
        drop:update(0.016)
    end
    
    expect(drop.lifetime > 0, "Lifetime is still positive after 0.5 seconds")
    expect(not drop.dead, "Drop is not dead before lifetime expires")
    
    -- Update for another 0.6 seconds (total > 1.0)
    for i = 1, 40 do
        drop:update(0.016)
    end
    
    expect(drop.lifetime <= 0, "Lifetime is zero or negative after expiring")
    expect(drop.dead, "Drop is marked dead after lifetime expires")
    expect(#G.player.inventory == 0, "Player did not pick up expired drop")
end

-- Test 6: Merging Mechanics - Basic Merge
print("\n-- Test 6: Merging mechanics - basic merge")
do
    G.player:reset()
    G.entities:clear()
    
    -- Create two ItemDrops of same block type at same position
    local drop1 = ItemDrop.new(0, 0, 0, 10, 5, 300, 0)
    local drop2 = ItemDrop.new(0, 0, 0, 10, 3, 300, 0)
    G.entities:add(drop1)
    G.entities:add(drop2)
    
    -- Position player far away to prevent pickup
    G.player.position.x = 1000
    G.player.position.y = 1000
    G.player.position.z = 0
    
    -- Update drop1 (should merge with drop2)
    drop1:update(0.016)
    
    expect(drop1.count == 8, "Drop1 merged with drop2 (5 + 3 = 8)")
    expect(drop2.dead, "Drop2 is marked dead after merge")
end

print("\n-- Test 7: Merging mechanics - different block types don't merge")
do
    G.player:reset()
    G.entities:clear()
    
    -- Create two ItemDrops of different block types at same position
    local drop1 = ItemDrop.new(0, 0, 0, 11, 5, 300, 0)
    local drop2 = ItemDrop.new(0, 0, 0, 12, 3, 300, 0)
    G.entities:add(drop1)
    G.entities:add(drop2)
    
    -- Position player far away
    G.player.position.x = 1000
    G.player.position.y = 1000
    G.player.position.z = 0
    
    -- Update drop1 (should NOT merge with drop2 due to different block_id)
    drop1:update(0.016)
    
    expect(drop1.count == 5, "Drop1 did not merge (different block_id)")
    expect(drop2.count == 3, "Drop2 count unchanged")
    expect(not drop2.dead, "Drop2 is not dead (no merge)")
end

print("\n-- Test 8: Merging mechanics - different layers don't merge")
do
    G.player:reset()
    G.entities:clear()
    
    -- Create two ItemDrops of same block type but different layers
    local drop1 = ItemDrop.new(0, 0, 0, 13, 4, 300, 0)
    local drop2 = ItemDrop.new(0, 0, 1, 13, 6, 300, 0)
    G.entities:add(drop1)
    G.entities:add(drop2)
    
    -- Position player far away
    G.player.position.x = 1000
    G.player.position.y = 1000
    G.player.position.z = 0
    
    -- Update drop1 (should NOT merge with drop2 due to different layer)
    drop1:update(0.016)
    
    expect(drop1.count == 4, "Drop1 did not merge (different layer)")
    expect(drop2.count == 6, "Drop2 count unchanged")
    expect(not drop2.dead, "Drop2 is not dead (no merge)")
end

print("\n-- Test 9: Merging mechanics - MERGE_RANGE tolerance")
do
    G.player:reset()
    G.entities:clear()
    
    -- Create two ItemDrops of same block type at close but not exact position
    -- MERGE_RANGE = BLOCK_SIZE / 2 = 8
    local drop1 = ItemDrop.new(0, 0, 0, 14, 2, 300, 0)
    local drop2 = ItemDrop.new(7, 0, 0, 14, 3, 300, 0)  -- 7 units away (within MERGE_RANGE)
    G.entities:add(drop1)
    G.entities:add(drop2)
    
    -- Position player far away
    G.player.position.x = 1000
    G.player.position.y = 1000
    G.player.position.z = 0
    
    -- Update drop1 (should merge with drop2 due to MERGE_RANGE)
    drop1:update(0.016)
    
    expect(drop1.count == 5, "Drop1 merged with drop2 within MERGE_RANGE (2 + 3 = 5)")
    expect(drop2.dead, "Drop2 is marked dead after merge")
end

print("\n-- Test 10: Merging mechanics - beyond MERGE_RANGE doesn't merge")
do
    G.player:reset()
    G.entities:clear()
    
    -- Create two ItemDrops of same block type far apart
    -- MERGE_RANGE = BLOCK_SIZE / 2 = 8
    local drop1 = ItemDrop.new(0, 0, 0, 15, 7, 300, 0)
    local drop2 = ItemDrop.new(50, 0, 0, 15, 9, 300, 0)  -- 50 units away (beyond MERGE_RANGE)
    G.entities:add(drop1)
    G.entities:add(drop2)
    
    -- Position player far away
    G.player.position.x = 1000
    G.player.position.y = 1000
    G.player.position.z = 0
    
    -- Update drop1 (should NOT merge with drop2 due to distance)
    drop1:update(0.016)
    
    expect(drop1.count == 7, "Drop1 did not merge (beyond MERGE_RANGE)")
    expect(drop2.count == 9, "Drop2 count unchanged")
    expect(not drop2.dead, "Drop2 is not dead (no merge)")
end

print("\n-- Test 11: Multiple updates and physics")
do
    G.player:reset()
    G.entities:clear()
    
    -- Create an ItemDrop above ground with initial velocity
    local drop = ItemDrop.new(0, -50, 0, 16, 1, 300, 0.5)
    G.entities:add(drop)
    
    -- Position player far away
    G.player.position.x = 1000
    G.player.position.y = 1000
    G.player.position.z = 0
    
    local initial_y = drop.position.y
    local initial_vy = drop.velocity.y
    
    -- Update many times to overcome initial upward velocity and fall
    for i = 1, 50 do
        drop:update(0.016)
    end
    
    -- Drop should have fallen (y increased, since y+ is down)
    -- After 50 updates (0.8 seconds), gravity should have overcome initial upward velocity
    expect(drop.position.y > initial_y, "Drop fell under gravity")
    -- Velocity should have increased (become more positive) due to gravity
    expect(drop.velocity.y > initial_vy, "Velocity increased due to gravity")
    expect(not drop.dead, "Drop is not dead while falling")
end

print("\n=== All ItemDrop tests passed! ===")
