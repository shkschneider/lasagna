--[[
    Main application (uses world.lua for generation + drawing helpers)
    - The per-layer drawing helper was moved into World:draw().
    - main.lua now delegates layer rendering to Game.world:draw(...)
    - LOVE-specific code (input, canvases, draw loop) remains here
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
    DIRT_THICKNESS = 10,
    STONE_THICKNESS = 10,

    -- Layer base heights per z
    LAYER_BASE_HEIGHTS = { [-1] = 20, [0] = 30, [1] = 40 },

    -- Mutable world/state
    world = nil,
    canvases = {},
    camera_x = 0,
    screen_width = 0,
    screen_height = 0,
    seed = nil,

    -- Player state
    player = { px = 50, py = 0, width = 1, height = 2, vx = 0, vy = 0, z = 0, on_ground = false },

    -- Debug flag
    debug = false,
}

-- Blocks table
Blocks = {
    grass = { color = {0.2, 0.6, 0.2, 1.0}, name = "grass" },
    dirt  = { color = {0.6, 0.3, 0.1, 1.0}, name = "dirt"  },
    stone = { color = {0.5, 0.52, 0.55, 1.0}, name = "stone" },
    player = { color = {1.0, 1.0, 1.0, 1.0}, name = "player" },
}

-- compatibility for unpack across Lua versions (Lua 5.2+ vs 5.1 / LuaJIT)
local unpack = table.unpack or unpack or function(t)
    return t[1], t[2], t[3], t[4]
end

-- Require the World module
local World = require("world")

-- Helper functions
local function getSeedFromArgs()
    local args_tbl = arg or {}
    for i = 1, #args_tbl do
        local v = args_tbl[i]
        if type(v) == "string" then
            local val = v:match("^%-%-seed=(.+)$")
            if val then return tonumber(val) or val end
            if v == "--seed" and args_tbl[i+1] then return tonumber(args_tbl[i+1]) or args_tbl[i+1] end
        end
    end
    return nil
end

local function clamp_camera()
    local max_camera = Game.WORLD_WIDTH * Game.BLOCK_SIZE - Game.screen_width
    if max_camera < 0 then max_camera = 0 end
    Game.camera_x = math.max(0, math.min(Game.camera_x, max_camera))
end

-- Regenerate world and recreate layer canvases (delegates per-layer rendering to World:draw)
local function regenerate_world()
    if not Game.world then
        Game.world = World.new(Game.seed, {
            width = Game.WORLD_WIDTH,
            height = Game.WORLD_HEIGHT,
            dirt_thickness = Game.DIRT_THICKNESS,
            stone_thickness = Game.STONE_THICKNESS,
            layer_base_heights = Game.LAYER_BASE_HEIGHTS,
        })
    else
        Game.world:regenerate()
    end

    local canvas_w = Game.WORLD_WIDTH * Game.BLOCK_SIZE
    local canvas_h = Game.WORLD_HEIGHT * Game.BLOCK_SIZE

    for z = -1, 1 do
        local canvas = love.graphics.newCanvas(canvas_w, canvas_h)
        canvas:setFilter("nearest", "nearest")
        Game.canvases[z] = canvas
        -- Use the new World:draw helper to render the layer into the canvas
        Game.world:draw(z, canvas, Blocks, Game.BLOCK_SIZE)
    end

    -- Position player on default layer surface
    if not Game.player.px or Game.player.px < 1 or Game.player.px > Game.WORLD_WIDTH then
        Game.player.px = 50
    end
    local top = Game.world:get_surface(0, math.floor(Game.player.px)) or (Game.WORLD_HEIGHT - 1)
    Game.player.py = top - Game.player.height

    clamp_camera()
end

function love.load()
    love.window.setMode(1280, 720, { resizable = true, minwidth = 640, minheight = 480 })
    love.window.setTitle("Lasagna")

    Game.screen_width = love.graphics.getWidth()
    Game.screen_height = love.graphics.getHeight()

    Game.seed = getSeedFromArgs() or os.time()

    local dbg_env = os.getenv and os.getenv("DEBUG")
    if not Game.debug and dbg_env then
        local v = tostring(dbg_env):lower()
        if v == "1" or v == "true" or v == "yes" then Game.debug = true end
    end

    regenerate_world()
end

function love.resize(w, h)
    Game.screen_width = w
    Game.screen_height = h
    clamp_camera()
end

function love.keypressed(key)
    if key == "q" then
        Game.player.z = math.max(-1, Game.player.z - 1)
        local top = Game.world:get_surface(Game.player.z, math.floor(Game.player.px)) or (Game.WORLD_HEIGHT - 1)
        Game.player.py = top - Game.player.height
        Game.player.vy = 0
    elseif key == "e" then
        Game.player.z = math.min(1, Game.player.z + 1)
        local top = Game.world:get_surface(Game.player.z, math.floor(Game.player.px)) or (Game.WORLD_HEIGHT - 1)
        Game.player.py = top - Game.player.height
        Game.player.vy = 0
    elseif key == "backspace" then
        Game.debug = not Game.debug
    elseif key == "delete" then
        if Game.debug then
            Game.player.px = 50
            Game.player.z = 0
            Game.player.vx = 0
            Game.player.vy = 0
            Game.player.on_ground = false
            regenerate_world()
            Game.player.vx = 0
            Game.player.vy = 0
            Game.player.on_ground = false
            clamp_camera()
        end
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
    Game.player.vx = 0
    if love.keyboard.isDown("d") then
        Game.player.vx = Game.MOVE_SPEED
    elseif love.keyboard.isDown("a") then
        Game.player.vx = -Game.MOVE_SPEED
    end

    local new_px = Game.player.px + Game.player.vx * dt
    local center_x = Game.player.px + Game.player.width / 2
    local new_center_x = new_px + Game.player.width / 2

    local current_ground_y = Game.world:get_surface(Game.player.z, math.floor(center_x)) or (Game.WORLD_HEIGHT - 1)
    local target_ground_y  = Game.world:get_surface(Game.player.z, math.floor(new_center_x)) or (Game.WORLD_HEIGHT - 1)

    if target_ground_y <= current_ground_y + Game.STEP_HEIGHT or Game.player.vy < 0 then
        Game.player.px = new_px
    end

    Game.player.px = math.max(1, math.min(Game.WORLD_WIDTH - Game.player.width, Game.player.px))

    Game.player.vy = Game.player.vy + Game.GRAVITY * dt
    Game.player.py = Game.player.py + Game.player.vy * dt

    local ground_y = Game.world:get_surface(Game.player.z, math.floor(Game.player.px + Game.player.width / 2)) or (Game.WORLD_HEIGHT - 1)
    if Game.player.vy > 0 and Game.player.py + Game.player.height > ground_y then
        Game.player.py = ground_y - Game.player.height
        Game.player.vy = 0
        Game.player.on_ground = true
    else
        Game.player.on_ground = false
    end

    Game.player.py = math.min(Game.player.py, Game.WORLD_HEIGHT - Game.player.height)

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
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, 0, 0)
    love.graphics.pop()
end

-- Helper to get block type at column x and block-row y for a specific layer z
local function get_block_type_at(z, x, by)
    if not Game.world then return "out" end
    return Game.world:get_block_type(z, x, by)
end

function love.draw()
    for z = -1, Game.player.z do
        draw_layer(z)
        if z == Game.player.z then
            love.graphics.push()
            love.graphics.origin()
            love.graphics.translate(-Game.camera_x, 0)
            love.graphics.setColor(unpack(Blocks.player.color))
            love.graphics.rectangle("fill",
                    (Game.player.px - 1) * Game.BLOCK_SIZE,
                    (Game.player.py - 1) * Game.BLOCK_SIZE,
                    Game.BLOCK_SIZE * Game.player.width,
                    Game.BLOCK_SIZE * Game.player.height)
            love.graphics.pop()
        end
    end

    love.graphics.origin()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Seed: " .. tostring(Game.seed), Game.screen_width / 2 - 30, 10)
    love.graphics.print(string.format("Layer: %d  Pos: %.2f, %.2f  OnGround: %s  Vx: %.2f Vy: %.2f",
            Game.player.z, Game.player.px, Game.player.py, tostring(Game.player.on_ground), Game.player.vx, Game.player.vy), 10, 10)

    if Game.debug then
        local mx, my = love.mouse.getPosition()
        local col = math.floor((mx + Game.camera_x) / Game.BLOCK_SIZE) + 1
        col = math.max(1, math.min(Game.WORLD_WIDTH, col))
        local by = math.floor(my / Game.BLOCK_SIZE) + 1
        by = math.max(1, math.min(Game.WORLD_HEIGHT, by))

        local layer_z = Game.player.z
        local block_type = get_block_type_at(layer_z, col, by)

        local debug_lines = {}
        debug_lines[#debug_lines+1] = "DEBUG MODE: ON (Backspace to toggle)"
        debug_lines[#debug_lines+1] = string.format("Mouse pixel: %.0f, %.0f", mx, my)
        debug_lines[#debug_lines+1] = string.format("World col,row: %d, %d", col, by)
        debug_lines[#debug_lines+1] = string.format("Layer (player): %d", layer_z)
        debug_lines[#debug_lines+1] = "Block: " .. tostring(block_type)
        debug_lines[#debug_lines+1] = "Press Delete to reset world"

        local padding = 6
        local line_h = 14
        local box_w = 260
        local box_h = #debug_lines * line_h + padding * 2
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 6, 6, box_w, box_h)
        love.graphics.setColor(1, 1, 1, 1)
        for i, ln in ipairs(debug_lines) do
            love.graphics.print(ln, 10, 6 + padding + (i-1) * line_h)
        end
    end
end