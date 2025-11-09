return {
    NAME = "Lasagna",
    RESOLUTIONS = {
        SD = { p = 480,  width = 854,  height = 480 },
        HD = { p = 720,  width = 1280, height = 720 },
        FHD = { p = 1080, width = 1920, height = 1080 },
    },
    FPS = 60,
    -- math precision
    EPS = 1e-6,
    -- world geometry & rendering
    BLOCK_SIZE = 8, -- pixels
    WORLD_HEIGHT = 200, -- blocks
    HEIGHT = 100,
    DIRT_THICKNESS = 10,
    STONE_THICKNESS = 10,
    LAYER_MIN = -1,
    LAYER_MAX = 1,
    -- movements constants
    GRAVITY = 40,    -- blocks / second^2 (2x for 2x2 subdivision)
    MOVE_ACCEL = 120, -- blocks / second^2 (2x for 2x2 subdivision)
    MAX_SPEED = 12,   -- blocks / second (2x for 2x2 subdivision)
    GROUND_FRICTION = 60, -- deceleration when no input and on ground (2x for 2x2 subdivision)
    AIR_ACCEL_MULT = 0.35, -- fraction of MOVE_ACCEL available in air
    AIR_FRICTION = 3, -- small deceleration in air when no input (2x for 2x2 subdivision)
    RUN_SPEED_MULT = 1.6, -- multiplier to MAX_SPEED when running
    RUN_ACCEL_MULT = 1.2, -- multiplier to MOVE_ACCEL when running
    CROUCH_DECEL = 240,  -- 2x for 2x2 subdivision
    CROUCH_MAX_SPEED = 6,  -- 2x for 2x2 subdivision
    JUMP_SPEED = -20,-- initial jump velocity (2x for 2x2 subdivision)
    STEP_HEIGHT = 2, -- maximum step-up in blocks (2x for 2x2 subdivision)
    -- gameplay constants
    MAX_STACK = 64,
    DESPAWN_TIME = 60, -- seconds
    -- day/night cycle
    DAY_DURATION = 60, -- seconds
    NIGHT_DURATION = 30, -- seconds
    -- procedural generation parameters (per-layer tables)
    GROUND_LEVEL = 30,
    LAYER_AMPLITUDE = 10,
    LAYER_FREQUENCY = 50,
    ground_level = function (z)
        if z < 0 then
            return C.GROUND_LEVEL + 10 * z
        elseif z < 0 then
            return C.GROUND_LEVEL - 10 * z
        else
            return C.GROUND_LEVEL
        end
    end,
    layer_amplitude = function (z)
        if z < 0 then
            return C.LAYER_AMPLITUDE - 5 * z
        else
            return C.LAYER_AMPLITUDE
        end
    end,
    layer_frequency = function (z)
        if z < 0 then
            return 1 / (C.LAYER_FREQUENCY - 10 * z)
        elseif z < 0 then
            return 1 / (C.LAYER_FREQUENCY + 10 * z)
        else
            return 1 / C.LAYER_FREQUENCY
        end
    end,
}
