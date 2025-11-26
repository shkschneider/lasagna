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
    _progress = 0, -- Loading progress 0.0 to 1.0
}

-- Start loading process
function LoaderSystem.start(self)
    self._elapsed = 0
    self._done = false
    self._progress = 0
    self._coroutine = coroutine.create(function()
        self._progress = 0.1
        G.menu:load()
        coroutine.yield() -- yield after menu load to update display
        self._progress = 0.3
        Love.load(G)
        coroutine.yield() -- yield after game systems load
        self._progress = 0.8
        -- Apply save data if we were loading a saved game
        if G.pending_save_data then
            G.save:apply_save_data(G.pending_save_data)
            G.pending_save_data = nil
        end
        self._progress = 1.0
    end)
end

-- Reset loader state
function LoaderSystem.reset(self)
    self._coroutine = nil
    self._elapsed = 0
    self._done = false
    self._progress = 0
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

-- Get current loading progress (0.0 to 1.0)
function LoaderSystem.get_progress(self)
    return self._progress
end

return LoaderSystem
