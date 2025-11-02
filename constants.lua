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
    BLOCK_SIZE = 16,
    WORLD_HEIGHT = 100,
    HEIGHT = 100,
    DIRT_THICKNESS = 10,
    STONE_THICKNESS = 10,
    LAYER_MIN = -1,
    LAYER_MAX = 1,
    -- procedural generation parameters (per-layer tables)
    LAYER_BASE_HEIGHTS = { [-1] = 20, [0] = 30, [1] = 40 },
    AMPLITUDE = { [-1] = 15, [0] = 10, [1] = 10 },
    FREQUENCY = { [-1] = 1/40, [0] = 1/50, [1] = 1/60 },
    -- gameplay constants
    GRAVITY = 20,    -- blocks / second^2
    MOVE_ACCEL = 60, -- blocks / second^2 (horizontal accel on ground)
    MAX_SPEED = 6,   -- blocks / second (base horizontal velocity)
    GROUND_FRICTION = 30, -- deceleration when no input and on ground
    AIR_ACCEL_MULT = 0.35, -- fraction of MOVE_ACCEL available in air
    AIR_FRICTION = 1.5, -- small deceleration in air when no input
    RUN_SPEED_MULT = 1.6, -- multiplier to MAX_SPEED when running
    RUN_ACCEL_MULT = 1.2, -- multiplier to MOVE_ACCEL when running
    CROUCH_DECEL = 120,
    CROUCH_MAX_SPEED = 3,
    JUMP_SPEED = -10,-- initial jump velocity (blocks per second)
    STEP_HEIGHT = 1, -- maximum step-up in blocks
    MAX_STACK = 16,
}
