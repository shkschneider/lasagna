--[[
    Lasagna (Canvas per layer + controls updated)
    - One Canvas per layer (pre-rendered at load time).
    - Controls changed: 'q' -> go back one layer, 'e' -> go up one layer.
      'w' and 's' are unused now.
    - Player positioning on layer change preserved.
--]]

-- Global game table
Game = {
    -- Constants (UPPERCASE)
    BLOCK_SIZE = 16,
    WORLD_WIDTH = 500,
    WORLD_HEIGHT = 100,
    GRAVITY = 20,    -- blocks / second^2
    MOVE_SPEED = 5,  -- blocks / second
    JUMP_SPEED = -10,-- initial jump velocity (blocks per second)
    STEP_HEIGHT = 1, -- maximum step-up in blocks

    -- How much dirt above stone and how thick stone is
    DIRT_THICKNESS = 10,   -- how many dirt blocks below the top before stone starts
    STONE_THICKNESS = 10,  -- how many stone blocks immediately below dirt

    -- Layer base heights per z (treat as constant)
    LAYER_BASE_HEIGHTS = { [-1] = 20, [0] = 30, [1] = 40 },

    -- Mutable world/state (lowercase per request)
    layers = {},            -- generation data: heights/dirt_limit/stone_limit per layer
    canvases = {},          -- canvases per layer (z -> love Canvas)
    camera_x = 0,
    screen_width = 0,
    screen_height = 0,
    seed = nil,

    -- Player state (lowercase)
    player = { px = 50, py = 0, width = 1, height = 2, vx = 0, vy = 0, z = 0, on_ground = false }
}

-- Require noise module (it exposes init and perlin1d)
local noise = require("noise1d")

-- Try to read a seed from command-line args.
-- Supported forms:
--    --seed=12345
--    --seed 12345
local function getSeedFromArgs()
    local args_tbl = arg or {}
    for i = 1, #args_tbl do
        local v = args_tbl[i]
        if type(v) == "string" then
            local val = v:match("^%-%-seed=(.+)$")
            if val then
                return tonumber(val) or val
            end
            if v == "--seed" and args_tbl[i+1] then
                return tonumber(args_tbl[i+1]) or args_tbl[i+1]
            end
        end
    end
    return nil
end

-- Helper to clamp camera_x to valid range after screen/world size changes
local function clamp_camera()
    local max_camera = Game.WORLD_WIDTH * Game.BLOCK_SIZE - Game.screen_width
    if max_camera < 0 then max_camera = 0 end
    Game.camera_x = math.max(0, math.min(Game.camera_x, max_camera))
end

-- Render a layer into its canvas. Assumes generation data exists in Game.layers[z].
local function render_layer_to_canvas(z)
    local layer = Game.layers[z]
    if not layer then return end

    local canvas = Game.canvases[z]
    if not canvas then return end

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0) -- clear to transparent (we'll draw opaque tiles)
    love.graphics.origin()

    -- draw entire layer
    for x = 1, Game.WORLD_WIDTH do
        local top = layer.heights[x]
        if top then
            local px = (x - 1) * Game.BLOCK_SIZE

            -- Draw grass/top
            local py = (top - 1) * Game.BLOCK_SIZE
            love.graphics.setColor(0.2, 0.6, 0.2, 1.0)
            love.graphics.rectangle("fill", px, py, Game.BLOCK_SIZE, Game.BLOCK_SIZE)

            -- Dirt: draw from top+1 up to dirt_limit
            local dirt_limit = layer.dirt_limit[x] or math.min(Game.WORLD_HEIGHT, top + Game.DIRT_THICKNESS)
            dirt_limit = math.min(dirt_limit, Game.WORLD_HEIGHT)
            love.graphics.setColor(0.6, 0.3, 0.1, 1.0)
            for y = top + 1, dirt_limit do
                local dy = (y - 1) * Game.BLOCK_SIZE
                love.graphics.rectangle("fill", px, dy, Game.BLOCK_SIZE, Game.BLOCK_SIZE)
            end

            -- Stone: draw from dirt_limit+1 up to stone_limit
            local stone_limit = layer.stone_limit[x] or math.min(Game.WORLD_HEIGHT, top + Game.DIRT_THICKNESS + Game.STONE_THICKNESS)
            stone_limit = math.min(stone_limit, Game.WORLD_HEIGHT)
            if dirt_limit + 1 <= stone_limit then
                love.graphics.setColor(0.5, 0.52, 0.55, 1.0) -- gray-ish stone
                for y = dirt_limit + 1, stone_limit do
                    local dy = (y - 1) * Game.BLOCK_SIZE
                    love.graphics.rectangle("fill", px, dy, Game.BLOCK_SIZE, Game.BLOCK_SIZE)
                end
            end
        end
    end

    -- reset color and canvas
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas()
end

function love.load()
    -- Make the window resizable
    love.window.setMode(1280, 720, { resizable = true, minwidth = 640, minheight = 480 })
    love.window.setTitle("Lasagna")

    -- Initialize screen dimensions from the window
    Game.screen_width = love.graphics.getWidth()
    Game.screen_height = love.graphics.getHeight()

    -- Determine seed: prefer CLI, fall back to time-based seed
    Game.seed = getSeedFromArgs() or os.time()
    math.randomseed(Game.seed)
    noise.init(Game.seed)

    -- Generate layers (-1: back, 0: default, 1: front)
    for z = -1, 1 do
        Game.layers[z] = { heights = {}, dirt_limit = {}, stone_limit = {} }
        local base_height = Game.LAYER_BASE_HEIGHTS[z] or 35
        local amplitude = (z == -1) and 15 or 10
        local frequency = (z == -1) and (1/40) or ((z == 1) and (1/60) or (1/50))

        for x = 1, Game.WORLD_WIDTH do
            local noise_val = noise.perlin1d(x * frequency + (z * 100))
            local top = math.floor(base_height + amplitude * noise_val)
            top = math.max(1, math.min(Game.WORLD_HEIGHT - 1, top))

            -- compute dirt and stone limits for this column
            local dirt_lim = math.min(Game.WORLD_HEIGHT, top + Game.DIRT_THICKNESS)
            local stone_lim = math.min(Game.WORLD_HEIGHT, top + Game.DIRT_THICKNESS + Game.STONE_THICKNESS)

            Game.layers[z].heights[x] = top
            Game.layers[z].dirt_limit[x] = dirt_lim
            Game.layers[z].stone_limit[x] = stone_lim
        end
    end

    -- Create and render canvases for each layer
    local canvas_w = Game.WORLD_WIDTH * Game.BLOCK_SIZE
    local canvas_h = Game.WORLD_HEIGHT * Game.BLOCK_SIZE

    for z = -1, 1 do
        -- create canvas for the whole layer
        -- NOTE: these canvases can be large; monitor memory usage if you change world size.
        local canvas = love.graphics.newCanvas(canvas_w, canvas_h)
        canvas:setFilter("nearest", "nearest")
        Game.canvases[z] = canvas

        -- render the precomputed tiles into the canvas
        render_layer_to_canvas(z)
    end

    -- Set player starting position (on default layer grass)
    Game.player.py = Game.layers[0].heights[math.floor(Game.player.px)] - Game.player.height

    -- Ensure camera is clamped initially
    clamp_camera()
end

function love.resize(w, h)
    -- Update stored screen size when the window is resized
    Game.screen_width = w
    Game.screen_height = h
    -- Re-clamp camera so it remains valid with the new screen size
    clamp_camera()
end

function love.keypressed(key)
    if key == "q" then
        -- go back one layer
        Game.player.z = math.max(-1, Game.player.z - 1)
        Game.player.py = Game.layers[Game.player.z].heights[math.floor(Game.player.px)] - Game.player.height
        Game.player.vy = 0
    elseif key == "e" then
        -- go up one layer
        Game.player.z = math.min(1, Game.player.z + 1)
        Game.player.py = Game.layers[Game.player.z].heights[math.floor(Game.player.px)] - Game.player.height
        Game.player.vy = 0
    elseif key == "escape" then
        love.event.quit()
    elseif key == "space" or key == "up" then
        if Game.player.on_ground then
            Game.player.vy = Game.JUMP_SPEED
            Game.player.on_ground = false
        end
    end
end

function love.update(dt)
    -- Horizontal movement
    Game.player.vx = 0
    if love.keyboard.isDown("d") then
        Game.player.vx = Game.MOVE_SPEED
    elseif love.keyboard.isDown("a") then
        Game.player.vx = -Game.MOVE_SPEED
    end

    -- ---- HORIZONTAL COLLISION WITH STEP-UP ----
    local new_px = Game.player.px + Game.player.vx * dt
    local center_x = Game.player.px + Game.player.width / 2
    local new_center_x = new_px + Game.player.width / 2

    local current_ground_y = Game.layers[Game.player.z].heights[math.floor(center_x)] or (Game.WORLD_HEIGHT - 1)
    local target_ground_y  = Game.layers[Game.player.z].heights[math.floor(new_center_x)] or (Game.WORLD_HEIGHT - 1)

    if target_ground_y <= current_ground_y + Game.STEP_HEIGHT or Game.player.vy < 0 then
        Game.player.px = new_px
    end
    -- ----------------------------------------

    -- Clamp player x inside world
    Game.player.px = math.max(1, math.min(Game.WORLD_WIDTH - Game.player.width, Game.player.px))

    -- Apply gravity
    Game.player.vy = Game.player.vy + Game.GRAVITY * dt

    -- Update y position
    Game.player.py = Game.player.py + Game.player.vy * dt

    -- Ground collision (only when falling)
    local ground_y = Game.layers[Game.player.z].heights[math.floor(Game.player.px + Game.player.width / 2)] or (Game.WORLD_HEIGHT - 1)
    if Game.player.vy > 0 and Game.player.py + Game.player.height > ground_y then
        Game.player.py = ground_y - Game.player.height
        Game.player.vy = 0
        Game.player.on_ground = true
    else
        Game.player.on_ground = false
    end

    -- Clamp y (prevent falling through the world)
    Game.player.py = math.min(Game.player.py, Game.WORLD_HEIGHT - Game.player.height)

    -- Smooth camera horizontally (center on player)
    Game.camera_x = (Game.player.px + Game.player.width / 2) * Game.BLOCK_SIZE - Game.screen_width / 2
    clamp_camera()
end

-- Draw a layer by blitting its canvas
local function draw_layer(z)
    local canvas = Game.canvases[z]
    if not canvas then return end

    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(-Game.camera_x, 0)
    love.graphics.setColor(1, 1, 1, 1) -- fully opaque
    love.graphics.draw(canvas, 0, 0)
    love.graphics.pop()
end

function love.draw()
    -- Draw layers strictly back-to-front (-1 .. 1).
    -- Draw the player immediately after drawing the layer matching player.z so player is at the correct depth.
    for z = -1, 1 do
        draw_layer(z)

        if z == Game.player.z then
            love.graphics.push()
            love.graphics.origin()
            love.graphics.translate(-Game.camera_x, 0)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("fill",
                    (Game.player.px - 1) * Game.BLOCK_SIZE,
                    (Game.player.py - 1) * Game.BLOCK_SIZE,
                    Game.BLOCK_SIZE * Game.player.width,
                    Game.BLOCK_SIZE * Game.player.height)
            love.graphics.pop()
        end
    end

    -- HUD (unchanged)
    love.graphics.origin()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Seed: " .. tostring(Game.seed), Game.screen_width / 2 - 30, 10)
    love.graphics.print(string.format("Layer: %d  Pos: %.2f, %.2f  OnGround: %s  Vx: %.2f Vy: %.2f",
            Game.player.z, Game.player.px, Game.player.py, tostring(Game.player.on_ground), Game.player.vx, Game.player.vy), 10, 10)
end