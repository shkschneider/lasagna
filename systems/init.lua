-- Systems Module
-- Shared definitions and constants for systems

local systems = {
    -- System priority constants
    PRIORITY_GAME = 0,
    PRIORITY_WORLD = 10,
    PRIORITY_PLAYER = 20,
    PRIORITY_INPUT = 30,
    PRIORITY_PHYSICS = 40,
    PRIORITY_COLLISION = 50,
    PRIORITY_MINING = 60,
    PRIORITY_DROP = 70,
    PRIORITY_LAYER = 80,
    PRIORITY_CAMERA = 90,
    PRIORITY_RENDER = 100,
}

return systems
