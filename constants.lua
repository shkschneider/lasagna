return {
    NAME = "Lasagna",
    RESOLUTIONS = {
        SD = { p = 480,  width = 854,  height = 480 },
        HD = { p = 720,  width = 1280, height = 720 },
        FHD = { p = 1080, width = 1920, height = 1080 },
    },
    -- math precision
    EPS = 1e-6,
    -- world geometry & rendering
    BLOCK_SIZE = 8,  -- Changed from 16 to 8 for finer blocks (2x2 subdivision)
    WORLD_HEIGHT = 200,  -- 2x the original to accommodate 2x2 subdivision
    HEIGHT = 100,
    DIRT_THICKNESS = 10,
    STONE_THICKNESS = 10,
    LAYER_MIN = -1,
    LAYER_MAX = 1,
    -- procedural generation parameters (per-layer tables)
    LAYER_BASE_HEIGHTS = { [-1] = 20, [0] = 30, [1] = 40 },  -- Original values
    AMPLITUDE = { [-1] = 15, [0] = 10, [1] = 10 },  -- Original values
    FREQUENCY = { [-1] = 1/40, [0] = 1/50, [1] = 1/60 },
    -- gameplay constants
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
    MAX_STACK = 64,
    -- day/night cycle
    DAY_DURATION = 60,   -- seconds
    NIGHT_DURATION = 30, -- seconds
}
