local Love = require "core.love"
local Object = require "core.object"
local GameState = require "src.data.gamestate"

local Loader = Object {
    id = "loader",
    priority = 5, -- Run early in system updates
    MIN_TIME = 1, -- minimum loading screen time in seconds
    _coroutine = nil,
    _elapsed = 0,
    _done = false,
    _progress = 0, -- Loading progress 0.0 to 1.0
}

-- Start loading process
function Loader.start(self)
    local WorldData = require "src.data.worlddata"
    
    self._elapsed = 0
    self._done = false
    self._progress = 0
    self._coroutine = coroutine.create(function()
        self._progress = 0.05
        G.menu:load()
        coroutine.yield() -- yield after menu load to update display

        -- If loading a saved game, set the generator seed before Love.load
        if G.pending_save_data and G.pending_save_data.seed then
            G.world.generator.data = WorldData.new(G.pending_save_data.seed)
        end

        self._progress = 0.1
        Love.load(G)
        -- Generator updates progress from 10% to 90% during pregenerate_spawn_area

        self._progress = 0.95
        coroutine.yield()

        -- Apply save data if we were loading a saved game
        if G.pending_save_data then
            G.world.save:apply_save_data(G.pending_save_data)
            G.pending_save_data = nil
        end
        self._progress = 1.0
    end)
end

-- Set progress directly (can be called by other systems like generator)
function Loader.set_progress(self, progress)
    self._progress = progress
end

-- Reset loader state
function Loader.reset(self)
    self._coroutine = nil
    self._elapsed = 0
    self._done = false
    self._progress = 0
end

-- Update loading process, returns true when loading is complete and ready to transition
function Loader.update(self, dt)
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
function Loader.is_active(self)
    return self._coroutine ~= nil
end

-- Get current loading progress (0.0 to 1.0)
function Loader.get_progress(self)
    return self._progress
end

return Loader
