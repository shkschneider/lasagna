-- tests/saves.lua
-- CLI tests for src/world/save.lua autosave and save functionality.
-- Run from repo root:
--   lua ./tests/saves.lua

require "libraries.luax"

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

-- Simple test harness state
local mock = {
    chat_add_message_called = false,
    chat_message = nil,
    save_snapshot_called = false,
    save_snapshot_data = nil,
    player_is_dead = false,
}

-- Install global Log used by save.lua
Log = {
    debug = function(...) end,
    info = function(...) end,
    warning = function(...) end,
    error = function(...) end,
    verbose = function(...) end,
    level = 2,
}

-- Global constants used by save.lua
LAYER_MIN = -1
LAYER_MAX = 1

-- Global G mock
G = {
    VERSION = {
        major = 0,
        minor = 1,
        patch = nil,
        tostring = function(self) return "0.1.x" end,
    },
    world = {
        generator = {
            data = {
                seed = 12345,
                changes = { [-1] = {}, [0] = {}, [1] = {} },
                columns = { [-1] = {}, [0] = {}, [1] = {} },
            },
        },
    },
    player = {
        is_dead = function(self) return mock.player_is_dead end,
        position = { x = 100, y = 200, z = 0 },
        velocity = { x = 0, y = 0 },
        health = { current = 100, max = 100 },
        stamina = { current = 100, max = 100 },
        omnitool = { tier = 1 },
        hotbar = { size = 9, selected_slot = 1, slots = {} },
        backpack = { size = 27, selected_slot = 1, slots = {} },
    },
    chat = {
        add_message = function(self, msg)
            mock.chat_add_message_called = true
            mock.chat_message = msg
        end,
    },
}

-- Preload minimal mocks into package.loaded

-- core.object: used as Object{...} so return a callable that returns the table unchanged
package.loaded["core.object"] = function(tbl) return tbl end

-- stack mock
package.loaded["src.data.stack"] = {
    new = function(id, count, id_type)
        return { id = id, count = count, id_type = id_type }
    end,
}

-- serializer mock
package.loaded["libraries.bakpakin.binser"] = {
    serialize = function(data) return "serialized_data" end,
    deserialize = function(data) return { data } end,
}

-- love mock (minimal)
love = {
    filesystem = {
        write = function(path, data) return true end,
        read = function(path) return "data" end,
        getInfo = function(path) return { size = 100, modtime = 12345 } end,
        remove = function(path) return true end,
    },
}

-- Now require the save module
local Save = require("src.world.save")

-- Override save_snapshot for testing
local original_save_snapshot = Save.save_snapshot
Save.save_snapshot = function(self, save_data)
    mock.save_snapshot_called = true
    mock.save_snapshot_data = save_data
    return original_save_snapshot(self, save_data)
end

print("-- Test 1: autosave timer initialization")
do
    -- Reset save state
    Save._autosave_timer = nil
    Save._autosave_snapshot = nil
    Save._autosave_delay_timer = nil
    
    -- First update should initialize timer
    Save:update(0.1)
    
    expect(Save._autosave_timer ~= nil, "autosave timer initialized after first update")
    expect(Save._autosave_timer == Save.AUTOSAVE_INTERVAL - 0.1, "autosave timer decremented correctly")
end

print("-- Test 2: autosave triggers snapshot and message after interval")
do
    -- Reset save state
    Save._autosave_timer = 0.1  -- Almost expired
    Save._autosave_snapshot = nil
    Save._autosave_delay_timer = nil
    mock.chat_add_message_called = false
    mock.chat_message = nil
    mock.player_is_dead = false
    
    -- Update to trigger snapshot
    Save:update(0.2)
    
    expect(Save._autosave_snapshot ~= nil, "snapshot taken when timer expires")
    expect(mock.chat_add_message_called, "chat message displayed for autosave")
    expect(mock.chat_message == "Autosaving...", "correct autosave message shown")
    expect(Save._autosave_delay_timer == Save.AUTOSAVE_DELAY, "delay timer started")
    expect(Save._autosave_timer == Save.AUTOSAVE_INTERVAL, "autosave timer reset")
end

print("-- Test 3: autosave completes after delay")
do
    -- Setup: snapshot is pending
    Save._autosave_snapshot = { seed = 12345 }
    Save._autosave_delay_timer = 0.5
    mock.save_snapshot_called = false
    mock.player_is_dead = false
    
    -- Update but delay not complete
    Save:update(0.3)
    expect(not mock.save_snapshot_called, "save_snapshot NOT called before delay complete")
    expect(Save._autosave_snapshot ~= nil, "snapshot still pending")
    
    -- Update to complete delay
    Save:update(0.3)
    expect(mock.save_snapshot_called, "save_snapshot called after delay complete")
    expect(Save._autosave_snapshot == nil, "snapshot cleared after save")
end

print("-- Test 4: autosave cancelled if player dies during delay")
do
    -- Setup: snapshot is pending
    Save._autosave_snapshot = { seed = 12345 }
    Save._autosave_delay_timer = 0.5
    mock.save_snapshot_called = false
    
    -- Player dies during delay
    mock.player_is_dead = true
    
    -- Update
    Save:update(0.3)
    
    expect(not mock.save_snapshot_called, "save_snapshot NOT called when player is dead")
    expect(Save._autosave_snapshot == nil, "snapshot cancelled when player dies")
    expect(Save._autosave_delay_timer == nil, "delay timer cancelled when player dies")
    
    -- Reset
    mock.player_is_dead = false
end

print("-- Test 5: save() prevented when player is dead")
do
    mock.player_is_dead = true
    mock.save_snapshot_called = false
    
    local result = Save:save()
    
    expect(not result, "save() returns false when player is dead")
    expect(not mock.save_snapshot_called, "save_snapshot NOT called when player is dead")
    
    -- Reset
    mock.player_is_dead = false
end

print("-- Test 6: save() works when player is alive")
do
    mock.player_is_dead = false
    mock.save_snapshot_called = false
    
    local result = Save:save()
    
    expect(result, "save() returns true when player is alive")
    expect(mock.save_snapshot_called, "save_snapshot called when player is alive")
end

print("-- Test 7: is_player_dead() returns correct state")
do
    mock.player_is_dead = false
    expect(not Save:is_player_dead(), "is_player_dead() returns false when player alive")
    
    mock.player_is_dead = true
    expect(Save:is_player_dead(), "is_player_dead() returns true when player dead")
    
    -- Reset
    mock.player_is_dead = false
end

print("-- Test 8: autosave does not start new cycle when player is dead")
do
    -- Reset
    Save._autosave_timer = 0.1  -- Almost expired
    Save._autosave_snapshot = nil
    mock.chat_add_message_called = false
    mock.player_is_dead = true
    
    -- Update
    Save:update(0.2)
    
    expect(Save._autosave_snapshot == nil, "no snapshot taken when player is dead")
    expect(not mock.chat_add_message_called, "no autosave message when player is dead")
    
    -- Reset
    mock.player_is_dead = false
end

print("All tests finished.")
