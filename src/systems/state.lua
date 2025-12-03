local Love = require "core.love"
local Object = require "core.object"
local GameState = require "src.data.gamestate"

-- State system: manages game state transitions and state-specific logic
local StateSystem = Object {
    id = "state",
    priority = 1,  -- Run very early, before most other systems
}

function StateSystem.load(self)
    self.current = GameState.new(GameState.BOOT)
    Love.load(self)
end

function StateSystem.update(self, dt)
    -- Handle state-specific update logic
    local state = self.current.current
    
    -- Check for player death and transition to DEAD state
    -- Only check when in PLAY state
    if state == GameState.PLAY and G.player:is_dead() then
        self:transition_to(GameState.DEAD)
    end
    
    -- State system doesn't have child components, so no Love.update needed
end

-- Transition to a new state
function StateSystem.transition_to(self, new_state)
    Log.debug("State transition:", self.current:tostring(), "->", GameState.tostring_state(new_state))
    self.current = GameState.new(new_state)
end

-- Check if current state allows gameplay updates
function StateSystem.is_playing(self)
    local state = self.current.current
    return state == GameState.PLAY
end

-- Check if input should be ignored
function StateSystem.should_ignore_input(self)
    local state = self.current.current
    return state == GameState.MENU 
        or state == GameState.PAUSE 
        or state == GameState.LOAD 
        or state == GameState.DEAD
end

return StateSystem
