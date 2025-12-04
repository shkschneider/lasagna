-- tests/give.lua
-- CLI tests for data/commands/give.lua - tests giving blocks and items to player
-- Run from repo root:
--   LUA_PATH="./?.lua;./?/init.lua;;" lua5.1 ./tests/give.lua

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
    return string.gsub(template, 'x', function (_)
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

-- Mock Stack module
local Stack = {}
Stack.MAX_SIZE = 64

function Stack.new(id, count, id_type)
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
end

function Stack:is_empty()
    return self == nil or self.count <= 0
end

function Stack:is_full()
    return self.count >= Stack.MAX_SIZE
end

function Stack:get_id()
    return self.block_id or self.item_id
end

function Stack:get_type()
    if self.item_id then
        return "item"
    elseif self.block_id then
        return "block"
    end
    return nil
end

function Stack:can_merge(other)
    if other == nil then
        return false
    end
    if self.block_id and other.block_id then
        return self.block_id == other.block_id
    elseif self.item_id and other.item_id then
        return self.item_id == other.item_id
    end
    return false
end

function Stack:add(count)
    count = count or 1
    local space = Stack.MAX_SIZE - self.count
    local to_add = math.min(count, space)
    self.count = self.count + to_add
    return to_add
end

function Stack:space()
    return Stack.MAX_SIZE - self.count
end
package.loaded["src.entities.stack"] = Stack

-- Mock Inventory module
local Inventory = {}

function Inventory.new(size)
    local inventory = {
        slots = {},
        size = size or 9,
    }
    for i = 1, inventory.size do
        inventory.slots[i] = nil
    end
    return setmetatable(inventory, { __index = Inventory })
end

function Inventory:can_take(stack)
    if stack == nil or stack:is_empty() then
        return true
    end
    local remaining = stack.count
    -- Try to stack with existing slots
    for i = 1, self.size do
        local slot = self.slots[i]
        if slot and slot:can_merge(stack) then
            remaining = remaining - slot:space()
            if remaining <= 0 then
                return true
            end
        end
    end
    -- Try empty slots
    for i = 1, self.size do
        if self.slots[i] == nil then
            remaining = remaining - Stack.MAX_SIZE
            if remaining <= 0 then
                return true
            end
        end
    end
    return remaining <= 0
end

function Inventory:take(stack)
    if stack == nil or stack:is_empty() then
        return true
    end
    local remaining = stack.count
    -- First try to stack with existing slots
    for i = 1, self.size do
        local slot = self.slots[i]
        if slot and slot:can_merge(stack) then
            local added = slot:add(remaining)
            remaining = remaining - added
            if remaining <= 0 then
                return true
            end
        end
    end
    -- Then try empty slots
    for i = 1, self.size do
        if self.slots[i] == nil then
            local to_add = math.min(remaining, Stack.MAX_SIZE)
            self.slots[i] = Stack.new(stack:get_id(), to_add, stack:get_type())
            remaining = remaining - to_add
            if remaining <= 0 then
                return true
            end
        end
    end
    return remaining <= 0
end

function Inventory:count(id, id_type)
    local total = 0
    for i = 1, self.size do
        local slot = self.slots[i]
        if slot then
            if id_type == "item" and slot.item_id == id then
                total = total + slot.count
            elseif id_type == "block" and slot.block_id == id then
                total = total + slot.count
            elseif id_type == nil and slot:get_id() == id then
                total = total + slot.count
            end
        end
    end
    return total
end
package.loaded["src.entities.inventory"] = Inventory

-- Mock registries
local BlocksRegistry = {
    -- Mock some blocks with names
    [0] = { id = 0, name = "Sky" },
    [1] = { id = 1, name = "Air" },
    [2] = { id = 2, name = "Dirt" },
    [3] = { id = 3, name = "Grass" },
    [4] = { id = 4, name = "Stone" },
    [5] = { id = 5, name = "Wood" },
    [6] = { id = 6, name = "Copper Ore" },
    [13] = { id = 13, name = "Sand" },
    exists = function(self, id)
        -- Mock some block IDs (based on data/blocks/ids.lua)
        return id >= 0 and id <= 27
    end,
    get = function(self, id)
        return self[id]
    end,
    iterate = function(self)
        return pairs(self)
    end,
}
package.loaded["src.registries.blocks"] = BlocksRegistry

local ItemsRegistry = {
    -- Mock some items with names
    [1] = { id = 1, name = "Omnitool" },
    [2] = { id = 2, name = "Gun" },
    [3] = { id = 3, name = "Rocket Launcher" },
    exists = function(self, id)
        -- Mock some item IDs (based on data/items/ids.lua)
        return id >= 1 and id <= 3
    end,
    get = function(self, id)
        return self[id]
    end,
    iterate = function(self)
        return pairs(self)
    end,
}
package.loaded["src.registries.items"] = ItemsRegistry

local Registry = {
    Blocks = BlocksRegistry,
    Items = ItemsRegistry,
}
package.loaded["src.registries"] = Registry

-- Mock CommandsRegistry
local CommandsRegistry = {
    commands = {},
    register = function(self, definition)
        assert(definition.name, "Command must have a name")
        assert(not self.commands[definition.name], "Command already exists: " .. tostring(definition.name))
        self.commands[definition.name] = definition
        assert(definition.execute, "Command must have an execute function")
        return definition.name
    end,
    get = function(self, name)
        return self.commands[name]
    end,
    execute = function(self, name, args)
        local command = self:get(name)
        if command then
            return command.execute(args)
        end
        return false, "Unknown command: " .. tostring(name)
    end,
    exists = function(self, name)
        return self.commands[name] ~= nil
    end,
}
package.loaded["src.registries.commands"] = CommandsRegistry

-- Mock Player
local Player = {
    hotbar = Inventory.new(9),
    backpack = Inventory.new(27),
    add_to_inventory = function(self, block_id, count)
        local stack = Stack.new(block_id, count or 1, "block")
        -- Try backpack first for blocks
        if self.backpack:can_take(stack) then
            return self.backpack:take(stack)
        end
        -- Try hotbar as fallback
        if self.hotbar:can_take(stack) then
            return self.hotbar:take(stack)
        end
        return false
    end,
    add_item_to_inventory = function(self, item_id, count)
        local stack = Stack.new(item_id, count or 1, "item")
        -- Try hotbar first for items
        if self.hotbar:can_take(stack) then
            return self.hotbar:take(stack)
        end
        -- Try backpack as fallback
        if self.backpack:can_take(stack) then
            return self.backpack:take(stack)
        end
        return false
    end,
    reset = function(self)
        self.hotbar = Inventory.new(9)
        self.backpack = Inventory.new(27)
    end,
}

-- Mock global G object
G = {
    debug = true,
    player = Player,
}

-- Load the give command
require("data.commands.give")

print("=== Give Command Tests ===\n")

-- Test 1: Give a block with default quantity
print("-- Test 1: Give a block with default quantity")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"me", "4"})  -- STONE = 4
    expect(success, "Command succeeded")
    expect(message:find("Stone") and message:find("block"), "Message contains correct info")
    
    -- Check that player received the block
    local count = G.player.backpack:count(4, "block")
    expect(count == 1, "Player has 1 block in backpack")
end

-- Test 2: Give a block with specified quantity
print("\n-- Test 2: Give a block with specified quantity")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"me", "4", "10"})  -- STONE = 4 (not an item)
    expect(success, "Command succeeded")
    expect(message:find("10") and message:find("Stone") and message:find("block"), "Message contains correct info")
    
    -- Check that player received the blocks
    local count = G.player.backpack:count(4, "block")
    expect(count == 10, "Player has 10 blocks in backpack")
end

-- Test 3: Give an item with default quantity
print("\n-- Test 3: Give an item with default quantity")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"me", "1"})  -- OMNITOOL = 1
    expect(success, "Command succeeded")
    expect(message:find("Omnitool") and message:find("item"), "Message contains correct info")
    
    -- Check that player received the item
    local count = G.player.hotbar:count(1, "item")
    expect(count == 1, "Player has 1 item in hotbar")
end

-- Test 4: Give an item with specified quantity
print("\n-- Test 4: Give an item with specified quantity")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"me", "2", "5"})  -- GUN = 2
    expect(success, "Command succeeded")
    expect(message:find("5") and message:find("Gun") and message:find("item"), "Message contains correct info")
    
    -- Check that player received the items
    local count = G.player.hotbar:count(2, "item")
    expect(count == 5, "Player has 5 items in hotbar")
end

-- Test 5: Give large quantity that fills multiple stacks
print("\n-- Test 5: Give large quantity (multiple stacks)")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"me", "5", "200"})  -- WOOD = 5, 200 blocks
    expect(success, "Command succeeded")
    expect(message:find("200") and message:find("Wood") and message:find("block"), "Message contains correct info")
    
    -- Check that player received the blocks (should be in 4 stacks: 64+64+64+8)
    local count = G.player.backpack:count(5, "block")
    expect(count == 200, "Player has 200 blocks total")
end

-- Test 6: Error - invalid target
print("\n-- Test 6: Error - invalid target")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"them", "4", "1"})
    expect(not success, "Command failed")
    expect(message:find("Only 'me' is supported"), "Error message is correct")
end

-- Test 7: Error - missing arguments
print("\n-- Test 7: Error - missing arguments")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"me"})
    expect(not success, "Command failed")
    expect(message:find("Usage:"), "Error message shows usage")
end

-- Test 8: Error - invalid ID
print("\n-- Test 8: Error - invalid ID")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"me", "999"})  -- Non-existent ID
    expect(not success, "Command failed")
    expect(message:find("Unknown item or block"), "Error message is correct")
end

-- Test 9: Error - invalid quantity
print("\n-- Test 9: Error - invalid quantity")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"me", "4", "-5"})
    expect(not success, "Command failed")
    expect(message:find("Invalid quantity"), "Error message is correct")
end

-- Test 10: Give block by name (case insensitive)
print("\n-- Test 10: Give block by name (case insensitive)")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"me", "stone"})
    expect(success, "Command succeeded with lowercase name")
    expect(message:find("Stone") and message:find("block"), "Message contains correct info")
    expect(G.player.backpack:count(4, "block") == 1, "Player has 1 stone")
    
    G.player:reset()
    success, message = CommandsRegistry:execute("give", {"me", "DIRT", "5"})
    expect(success, "Command succeeded with uppercase name")
    expect(message:find("5") and message:find("Dirt") and message:find("block"), "Message contains correct info")
    expect(G.player.backpack:count(2, "block") == 5, "Player has 5 dirt")
end

-- Test 11: Give item by name
print("\n-- Test 11: Give item by name")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"me", "omnitool"})
    expect(success, "Command succeeded")
    expect(message:find("Omnitool") and message:find("item"), "Message contains correct info")
    expect(G.player.hotbar:count(1, "item") == 1, "Player has 1 omnitool")
    
    G.player:reset()
    success, message = CommandsRegistry:execute("give", {"me", "gun", "3"})
    expect(success, "Command succeeded")
    expect(message:find("3") and message:find("Gun") and message:find("item"), "Message contains correct info")
    expect(G.player.hotbar:count(2, "item") == 3, "Player has 3 guns")
end

-- Test 12: Error - unknown name
print("\n-- Test 12: Error - unknown name")
do
    G.player:reset()
    local success, message = CommandsRegistry:execute("give", {"me", "diamond"})
    expect(not success, "Command failed")
    expect(message:find("Unknown item or block name"), "Error message is correct")
end

-- Test 13: Give different block types
print("\n-- Test 13: Give different block types")
do
    G.player:reset()
    -- STONE = 4, WOOD = 5, COPPER_ORE = 6 (none are items)
    CommandsRegistry:execute("give", {"me", "4", "10"})
    CommandsRegistry:execute("give", {"me", "5", "20"})
    CommandsRegistry:execute("give", {"me", "6", "15"})
    
    expect(G.player.backpack:count(4, "block") == 10, "Player has 10 stone")
    expect(G.player.backpack:count(5, "block") == 20, "Player has 20 wood")
    expect(G.player.backpack:count(6, "block") == 15, "Player has 15 copper ore")
end

-- Test 14: Inventory full scenario (fill inventory then try to add more)
print("\n-- Test 14: Inventory full scenario")
do
    G.player:reset()
    -- Fill backpack (27 slots * 64 = 1728 items) and hotbar (9 slots * 64 = 576 items)
    -- Total capacity = 2304 blocks
    
    -- Fill most of the inventory
    CommandsRegistry:execute("give", {"me", "13", "2300"})  -- SAND = 13, 2300 blocks
    
    -- Try to add more than remaining capacity
    local success, message = CommandsRegistry:execute("give", {"me", "13", "100"})
    expect(not success, "Command failed when inventory full")
    expect(message:find("Inventory full"), "Error message is correct")
end

print("\n=== All Give Command tests passed! ===")
