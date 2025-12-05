-- tests/blockitems.lua
-- CLI tests for src/blockitems/ - tests workbench blockitem and recipe matching
-- Run from repo root:
--   LUA_PATH="./?.lua;./?/init.lua;;" lua5.1 ./tests/blockitems.lua

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

-- Mock love.graphics for Machine draw method
love = {
    graphics = {
        setColor = function(...) end,
        rectangle = function(...) end,
    }
}

-- Mock Registry
local BlocksRegistry = {
    blocks = {},
    get = function(self, id)
        return self.blocks[id]
    end,
}

local MockRegistry = {
    Blocks = BlocksRegistry,
}
package.loaded["src.registries"] = MockRegistry

-- Mock blocks
local BLOCKS = {
    AIR = 1,
    WOOD = 5,
    STONE = 4,
    GRAVEL = 15,
    WORKBENCH = 24,
}

-- Register mock blocks in the registry
BlocksRegistry.blocks[BLOCKS.WOOD] = {
    id = BLOCKS.WOOD,
    name = "Wood",
    color = {0.6, 0.4, 0.2, 1},
}
BlocksRegistry.blocks[BLOCKS.STONE] = {
    id = BLOCKS.STONE,
    name = "Stone",
    color = {0.5, 0.5, 0.5, 1},
}
BlocksRegistry.blocks[BLOCKS.GRAVEL] = {
    id = BLOCKS.GRAVEL,
    name = "Gravel",
    color = {0.6, 0.6, 0.6, 1},
}
BlocksRegistry.blocks[BLOCKS.WORKBENCH] = {
    id = BLOCKS.WORKBENCH,
    name = "Workbench",
    color = {0.7, 0.5, 0.3, 1},
}

-- Mock block IDs module
package.loaded["data.blocks.ids"] = BLOCKS

-- Mock world
local MockWorld = {
    block_to_world = function(col, row)
        return col * BLOCK_SIZE, row * BLOCK_SIZE
    end,
}

-- Mock entities system
local MockEntities = {
    _drops = {},
    _blockitems = {},
    getByType = function(self, entity_type)
        if entity_type == "drop" then
            return self._drops
        elseif entity_type == "blockitem" then
            return self._blockitems
        end
        return {}
    end,
    add = function(self, entity)
        if entity.type == "drop" then
            table.insert(self._drops, entity)
        elseif entity.type == "blockitem" then
            table.insert(self._blockitems, entity)
        end
    end,
    clear = function(self)
        self._drops = {}
        self._blockitems = {}
    end,
}

-- Mock global G object
G = {
    world = MockWorld,
    entities = MockEntities,
}

-- Load the BlockItem and Workbench modules
local BlockItem = require("src.blockitems.init")
local Workbench = require("src.blockitems.workbench")
local ItemDrop = require("src.entities.itemdrop")

print("=== BlockItem System Tests ===\n")

-- Test 1: BlockItem creation
print("-- Test 1: BlockItem creation")
do
    local blockitem = BlockItem.new(100, 100, 0, BLOCKS.WORKBENCH)
    expect(blockitem ~= nil, "BlockItem created")
    expect(blockitem.position.x == 100, "BlockItem has correct x position")
    expect(blockitem.position.y == 100, "BlockItem has correct y position")
    expect(blockitem.position.z == 0, "BlockItem has correct layer")
    expect(blockitem.block_id == BLOCKS.WORKBENCH, "BlockItem has correct block_id")
    expect(blockitem.type == "blockitem", "BlockItem has correct type")
    expect(not blockitem.dead, "BlockItem is not dead initially")
end

-- Test 2: Workbench creation
print("\n-- Test 2: Workbench creation")
do
    local workbench = Workbench.new(200, 200, 0, BLOCKS.WORKBENCH)
    expect(workbench ~= nil, "Workbench created")
    expect(workbench.position.x == 200, "Workbench has correct x position")
    expect(workbench.position.y == 200, "Workbench has correct y position")
    expect(workbench.type == "blockitem", "Workbench has correct type")
end

-- Test 3: Workbench detects items on top
print("\n-- Test 3: Workbench detects items on top")
do
    G.entities:clear()
    
    -- Create workbench at (0, 16) in world coords (col=0, row=1)
    local workbench = Workbench.new(0, 16, 0, BLOCKS.WORKBENCH)
    G.entities:add(workbench)
    
    -- Create an item drop on top of the workbench (at y=0, which is one block above y=16)
    local drop = ItemDrop.new(8, 8, 0, BLOCKS.WOOD, 4, 300, 0)
    G.entities:add(drop)
    
    local items = workbench:get_items_on_top()
    expect(#items == 1, "Workbench detects 1 item on top")
    expect(items[1].block_id == BLOCKS.WOOD, "Item is WOOD")
    expect(items[1].count == 4, "Item has count of 4")
end

-- Test 4: Workbench doesn't detect items that are not on top
print("\n-- Test 4: Workbench doesn't detect items that are not on top")
do
    G.entities:clear()
    
    -- Create workbench at (0, 16)
    local workbench = Workbench.new(0, 16, 0, BLOCKS.WORKBENCH)
    G.entities:add(workbench)
    
    -- Create an item drop far away
    local drop = ItemDrop.new(100, 100, 0, BLOCKS.WOOD, 2, 300, 0)
    G.entities:add(drop)
    
    local items = workbench:get_items_on_top()
    expect(#items == 0, "Workbench doesn't detect distant items")
end

-- Test 5: Item counting
print("\n-- Test 5: Item counting")
do
    G.entities:clear()
    
    local workbench = Workbench.new(0, 16, 0, BLOCKS.WORKBENCH)
    G.entities:add(workbench)
    
    -- Create multiple drops on top
    local drop1 = ItemDrop.new(8, 8, 0, BLOCKS.WOOD, 2, 300, 0)
    local drop2 = ItemDrop.new(8, 8, 0, BLOCKS.WOOD, 2, 300, 0)
    local drop3 = ItemDrop.new(8, 8, 0, BLOCKS.STONE, 1, 300, 0)
    G.entities:add(drop1)
    G.entities:add(drop2)
    G.entities:add(drop3)
    
    local items = workbench:get_items_on_top()
    local counts = Workbench.count_items(items)
    
    expect(counts[BLOCKS.WOOD] == 4, "Counted 4 WOOD total (2+2)")
    expect(counts[BLOCKS.STONE] == 1, "Counted 1 STONE")
end

-- Test 6: Recipe matching
print("\n-- Test 6: Recipe matching")
do
    -- Test exact match for recipe: 1 STONE -> 4 GRAVEL
    local item_counts = { [BLOCKS.STONE] = 1 }
    local recipe = Workbench.match_recipe(item_counts)
    expect(recipe ~= nil, "Recipe matches for 1 STONE")
    -- Check output format: { [block_id] = count }
    expect(recipe.output[BLOCKS.GRAVEL] == 4, "Recipe output is 4 GRAVEL")
    
    -- Test no match for wrong count
    item_counts = { [BLOCKS.STONE] = 2 }
    recipe = Workbench.match_recipe(item_counts)
    expect(recipe == nil, "No recipe match for 2 STONE")
    
    -- Test no match for extra items
    item_counts = { [BLOCKS.STONE] = 1, [BLOCKS.WOOD] = 1 }
    recipe = Workbench.match_recipe(item_counts)
    expect(recipe == nil, "No recipe match when extra items present")
end

-- Test 7: Recipe processing
print("\n-- Test 7: Recipe processing")
do
    G.entities:clear()
    
    local workbench = Workbench.new(0, 16, 0, BLOCKS.WORKBENCH)
    G.entities:add(workbench)
    
    -- Create exactly 1 STONE drop on top (matching the recipe: 1 STONE -> 4 GRAVEL)
    local drop = ItemDrop.new(8, 8, 0, BLOCKS.STONE, 1, 300, 0)
    G.entities:add(drop)
    
    expect(#G.entities._drops == 1, "Initial: 1 drop present")
    
    -- Update workbench (should process recipe)
    workbench:update(0.016)
    
    -- Input drop should be marked dead
    expect(drop.dead, "Input drop marked as dead")
    
    -- Output drop should be spawned (1 input dead, 1 output spawned)
    expect(#G.entities._drops == 2, "After processing: 2 drops (1 input dead, 1 output)")
    
    -- Find the output drop (not dead)
    local output_drop = nil
    for _, d in ipairs(G.entities._drops) do
        if not d.dead then
            output_drop = d
            break
        end
    end
    
    expect(output_drop ~= nil, "Output drop exists")
    expect(output_drop.block_id == BLOCKS.GRAVEL, "Output is GRAVEL")
    expect(output_drop.count == 4, "Output count is 4")
    
    -- Output should be at the bottom of the workbench
    local expected_y = 16 + BLOCK_SIZE + BLOCK_SIZE / 2
    expect(math.abs(output_drop.position.y - expected_y) < 1, "Output spawned at bottom of workbench")
end

-- Test 8: Multiple recipe updates don't duplicate
print("\n-- Test 8: Multiple updates don't re-process consumed items")
do
    G.entities:clear()
    
    local workbench = Workbench.new(0, 16, 0, BLOCKS.WORKBENCH)
    G.entities:add(workbench)
    
    -- Create exactly 1 STONE drop on top
    local drop = ItemDrop.new(8, 8, 0, BLOCKS.STONE, 1, 300, 0)
    G.entities:add(drop)
    
    -- First update processes the recipe
    workbench:update(0.016)
    expect(drop.dead, "Input consumed on first update")
    
    -- Remove dead drops (simulate entity system cleanup)
    local alive_drops = {}
    for _, d in ipairs(G.entities._drops) do
        if not d.dead then
            table.insert(alive_drops, d)
        end
    end
    G.entities._drops = alive_drops
    
    expect(#G.entities._drops == 1, "Only output drop remains after cleanup")
    
    -- Second update should not create more outputs
    workbench:update(0.016)
    expect(#G.entities._drops == 1, "Still only 1 drop after second update")
end

print("\n=== All BlockItem System tests passed! ===")
