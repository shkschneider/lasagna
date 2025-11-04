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
    BLOCK_SIZE = 4,
    WORLD_HEIGHT = 400,  -- 4x the original (100 * 4) to accommodate scaled terrain
    HEIGHT = 100,
    DIRT_THICKNESS = 10,
    STONE_THICKNESS = 10,
    LAYER_MIN = -1,
    LAYER_MAX = 1,
    -- procedural generation parameters (per-layer tables)
    LAYER_BASE_HEIGHTS = { [-1] = 80, [0] = 120, [1] = 160 },  -- 4x the original values
    AMPLITUDE = { [-1] = 60, [0] = 40, [1] = 40 },  -- 4x the original values
    FREQUENCY = { [-1] = 1/40, [0] = 1/50, [1] = 1/60 },
    -- gameplay constants
    GRAVITY = 80,    -- blocks / second^2 (4x original for scaled blocks)
    MOVE_ACCEL = 240, -- blocks / second^2 (4x original)
    MAX_SPEED = 24,   -- blocks / second (4x original)
    GROUND_FRICTION = 120, -- deceleration when no input and on ground (4x original)
    AIR_ACCEL_MULT = 0.35, -- fraction of MOVE_ACCEL available in air
    AIR_FRICTION = 6, -- small deceleration in air when no input (4x original)
    RUN_SPEED_MULT = 1.6, -- multiplier to MAX_SPEED when running
    RUN_ACCEL_MULT = 1.2, -- multiplier to MOVE_ACCEL when running
    CROUCH_DECEL = 480,  -- 4x original
    CROUCH_MAX_SPEED = 12,  -- 4x original
    JUMP_SPEED = -40,-- initial jump velocity (4x original)
    STEP_HEIGHT = 4, -- maximum step-up in blocks (4x original)
    MAX_STACK = 64,
    -- day/night cycle
    DAY_DURATION = 60,   -- seconds
    NIGHT_DURATION = 30, -- seconds
}
