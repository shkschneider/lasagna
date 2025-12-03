-- tests/states.lua
-- CLI tests for src/game.lua state transitions and subobject initialization.
-- Run from repo root:
--   lua ./tests/states.lua

require "libraries.luax"

local function ok(msg)
    io.stdout:write("PASS: " .. msg .. "\n")
end
local function fail(msg)
    io.stderr:write("FAIL: " .. msg .. "\n")
    os.exit(1)
end
local function expect(cond,msg)
    if cond then ok(msg) else fail(msg) end
end

-- Simple test harness state
local mock = {
    Love_load_called = false,
    Love_update_called = false,
    menu_loaded = false,
    loader_started = false,
    loader_update_called = false,
    loader_reset_called = false,
    debug_get_called = false,
    log_debug_called = false,
    log_info_called = false,
    chat_update_called = false,
    menu_keypressed_called = false,
    menu_keypressed_key = nil,
}

-- Install global Log used by game.lua
Log = {
    debug = function(...) mock.log_debug_called = true end,
    info  = function(...) mock.log_info_called = true end,
    level = 2,
}

-- Preload minimal mocks into package.loaded so require() in src/game.lua picks them up.

-- core.object: used as Object{...} so return a callable that returns the table unchanged
package.loaded["core.object"] = function(tbl) return tbl end

-- core.love: Love.load(self) called in Game.load during initial boot and Love.update called in Game.update
package.loaded["core.love"] = {
    load = function(self)
        mock.Love_load_called = true
    end,
    update = function(self, dt)
        mock.Love_update_called = true
    end,
    keypressed = function() end,
    mousepressed = function() end,
    mousereleased = function() end,
    mousemoved = function() end,
    wheelmoved = function() end,
    textinput = function() end,
    resize = function() end,
    focus = function() end,
    quit = function() end,
}

-- timescale (tiny)
package.loaded["src.data.timescale"] = {
    new = function(scale) return { scale = scale or 1 } end
}

-- GameState mock with constants and new()
package.loaded["src.data.gamestate"] = (function()
    local GS = {}
    GS.BOOT = "BOOT"
    GS.MENU = "MENU"
    GS.LOAD = "LOAD"
    GS.PLAY = "PLAY"
    GS.PAUSE = "PAUSE"
    GS.DEAD = "DEAD"
    GS.QUIT = "QUIT"
    function GS.new(state)
        local obj = { current = state or GS.BOOT }
        function obj:tostring()
            return tostring(self.current)
        end
        return obj
    end
    return GS
end)()

-- src.debug.get() returns a debug object or nil; we record the call
package.loaded["src.debug"] = {
    get = function()
        mock.debug_get_called = true
        return nil -- simulate no debug mode
    end
}

-- Minimal mocks for modules referenced in Game table
package.loaded["src.world"] = {}
package.loaded["src.ui.camera"] = {}

-- player mock with configurable is_dead
local player_mock = {
    _is_dead = false,
    is_dead = function(self) return self._is_dead end
}
package.loaded["src.entities.player"] = player_mock

package.loaded["src.world.mining"] = {}
package.loaded["src.world.building"] = {}
package.loaded["src.items.weapon"] = {}
package.loaded["src.entities"] = {}
package.loaded["src.ui"] = {}

-- chat mock with update function
local chat_mock = {
    update = function(self, dt) mock.chat_update_called = true end,
    add_message = function(self, msg) end,
}
package.loaded["src.chat"] = chat_mock
package.loaded["src.ui.chat"] = chat_mock

package.loaded["src.lore"] = {}

-- menu mock: menu:load() should be called when Game:load(state) is invoked after boot
package.loaded["src.ui.menu"] = {
    load = function() mock.menu_loaded = true end,
    keypressed = function() end,
}

-- loader mock: must implement is_active, start, update, reset
do
    local loader = {}
    loader._active = false
    -- configure this flag in tests to control when update() returns true
    loader._should_finish_next_update = false
    function loader:is_active() return loader._active end
    function loader:start()
        loader._active = true
        mock.loader_started = true
    end
    function loader:update(dt)
        mock.loader_update_called = true
        if loader._should_finish_next_update then
            loader._should_finish_next_update = false
            return true
        end
        return false
    end
    function loader:reset()
        loader._active = false
        mock.loader_reset_called = true
    end
    -- helper to set finishing behavior
    function loader:_set_finish_next(v) loader._should_finish_next_update = v end

    package.loaded["src.ui.loader"] = loader
end

-- renderer mock
package.loaded["src.renderer"] = {
    draw = function() end
}

-- Now require the game module (src/game.lua). This will use our mocks.
local Game = require("src.game")

-- Provide NAME and VERSION so Game:load assertions pass
Game.NAME = "TESTGAME"
Game.VERSION = { tostring = function() return "0.0-test" end }

print("-- Test 1: initial boot load (no state arg) should call Love.load and set state to MENU and call src.debug.get()")
do
    -- reset mocks
    mock.Love_load_called = false
    mock.debug_get_called = false
    -- call initial load
    Game:load()
    expect(mock.debug_get_called, "debug.get() called during initial load")
    expect(not mock.Love_load_called, "Love.load() called during initial load")
    expect(mock.menu_loaded, "menu:load() called during initial load")
    -- Game.state should be MENU per code path
    local GS = require("src.data.gamestate")
    expect(Game.state and Game.state.current == GS.MENU, "Game.state is MENU after initial load")
end

print("-- Test 2: calling Game:load(someState) after initial load should call menu:load()")
do
    mock.menu_loaded = false
    local GS = require("src.data.gamestate")
    -- Call load with explicit state; code requires self.state to exist which it does after initial load
    Game:load(GS.LOAD)
    expect(mock.menu_loaded, "menu:load() called when calling Game:load(state)")
end

print("-- Test 3: loader lifecycle in Game:update when state == LOAD")
do
    -- Prepare loader to finish on next update
    local loader = package.loaded["src.ui.loader"]
    loader:_set_finish_next(true)
    -- Ensure loader flags cleared
    mock.loader_started = false
    mock.loader_update_called = false
    mock.loader_reset_called = false

    -- set game state to LOAD explicitly
    local GS = require("src.data.gamestate")
    Game.state = GS.new(GS.LOAD)

    -- run update once (dt arbitrary)
    Game.time = require("src.data.timescale").new(1)
    Game:update(0.016)

    expect(mock.loader_started, "loader:start() called during LOAD update")
    expect(mock.loader_update_called, "loader:update() called during LOAD update")
    expect(mock.loader_reset_called, "loader:reset() called after loader finished")
    expect(Game.state and Game.state.current == GS.PLAY, "Game transitioned to PLAY after loader finished")
end

print("-- Test 4: player death transitions game to DEAD state")
do
    local GS = require("src.data.gamestate")
    local player = package.loaded["src.entities.player"]

    -- Set game to PLAY state
    Game.state = GS.new(GS.PLAY)

    -- Set player to dead
    player._is_dead = true

    -- run update
    Game.time = require("src.data.timescale").new(1)
    Game.fade_duration = 0
    Game:update(0.016)

    expect(Game.state and Game.state.current == GS.DEAD, "Game transitioned to DEAD when player died")

    -- Reset player state
    player._is_dead = false
end

print("-- Test 5: DEAD state ignores most input but allows return key")
do
    local GS = require("src.data.gamestate")
    mock.menu_keypressed_called = false

    -- Update menu mock to track keypressed
    local menu = package.loaded["src.ui.menu"]
    menu.keypressed = function(self, key)
        mock.menu_keypressed_called = true
        mock.menu_keypressed_key = key
    end

    -- Set game to DEAD state
    Game.state = GS.new(GS.DEAD)

    -- Try l key - should be passed to menu
    mock.menu_keypressed_called = false
    Game:keypressed("l")
    expect(mock.menu_keypressed_called, "l key passed to menu in DEAD state")
    expect(mock.menu_keypressed_key == "l", "correct key passed to menu")

    -- Try q key - should be passed to menu
    mock.menu_keypressed_called = false
    Game:keypressed("q")
    expect(mock.menu_keypressed_called, "q key passed to menu in DEAD state")
    expect(mock.menu_keypressed_key == "q", "correct key passed to menu")
end

print("All tests finished.")
