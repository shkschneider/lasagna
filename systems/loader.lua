local Love = require "core.love"
local Object = require "core.object"
local GameStateComponent = require "components.gamestate"

local LoaderSystem = Object {
    id = "loader",
    priority = 5, -- Run early in system updates
    MIN_TIME = 1, -- minimum loading screen time in seconds
    _coroutine = nil,
    _elapsed = 0,
    _done = false,
}

-- Start loading process
function LoaderSystem.start(self)
    self._elapsed = 0
    self._done = false
    self._coroutine = coroutine.create(function()
        G.menu:load()
        coroutine.yield() -- yield after menu load to update display
        Love.load(G)
        coroutine.yield() -- yield after game systems load
        -- Apply save data if we were loading a saved game
        if G.pending_save_data then
            G.save:apply_save_data(G.pending_save_data)
            G.pending_save_data = nil
        end
    end)
end

-- Reset loader state
function LoaderSystem.reset(self)
    self._coroutine = nil
    self._elapsed = 0
    self._done = false
end

-- Update loading process, returns true when loading is complete and ready to transition
function LoaderSystem.update(self, dt)
    if not self._coroutine then
        return false
    end

    -- Update elapsed time
    self._elapsed = self._elapsed + dt

    -- Resume loading coroutine if not done
    if not self._done then
        local ok, err = coroutine.resume(self._coroutine)
        if not ok then
            Log.error("Loading error:", err)
        end
        -- Mark loading as done when coroutine completes
        self._done = coroutine.status(self._coroutine) == "dead"
    end

    -- Return true when loading is done AND minimum time has elapsed
    return self._done and self._elapsed >= self.MIN_TIME
end

-- Check if loader is active
function LoaderSystem.is_active(self)
    return self._coroutine ~= nil
end

return LoaderSystem
