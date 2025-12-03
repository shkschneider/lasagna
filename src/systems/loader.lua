local Love = require "core.love"
local Object = require "core.object"
local GameState = require "src.data.gamestate"

-- LoaderSystem: manages game loading state and transitions
local LoaderSystem = Object {
    id = "loader_system",
    priority = 3,  -- Run after state and time systems
}

function LoaderSystem.load(self)
    self.ui = require("src.ui.loader")
    Love.load(self)
end

function LoaderSystem.update(self, dt)
    -- Only update when in LOAD state
    if G.state.current.current ~= GameState.LOAD then
        return
    end
    
    -- Start loader if not active
    if not self.ui:is_active() then
        self.ui:start()
    end
    
    -- Update loader and check if complete
    if self.ui:update(dt) then
        self.ui:reset()
        -- Transition to PLAY state
        -- Note: Direct call to G:load() is intentional for state coordination
        -- The Game.load() method handles menu initialization and other setup
        G:load(GameState.PLAY)
        -- Start fade-in when entering PLAY state
        G.fade:start_fade_in()
    end
    
    Love.update(self, dt)
end

return LoaderSystem
