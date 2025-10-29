-- Main application
-- Player produces intents; World.update(dt) applies physics/collision to registered entities.
-- World.draw handles full-scene composition; World.draw_layer draws a single canvas layer.

-- Global game table (world-related defaults moved here)
Game = {
    -- world geometry & rendering
    BLOCK_SIZE = 16,
    WORLD_WIDTH = 500,
    WORLD_HEIGHT = 100,
    DIRT_THICKNESS = 10,
    STONE_THICKNESS = 10,

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

    -- UI / runtime state
    world = nil,
    camera_x = 0,
    screen_width = 0,
    screen_height = 0,
    seed = nil,

    -- debug off by default
    debug = os.getenv("DEBUG") == "true",
}

-- Require modules and data
local World = require("world.world")
local Player = require("entities.player")
local Blocks = require("world.blocks")

-- logging and utilities
local log = require("lib.log")

-- configure logger level from Game.debug
if Game.debug then
    log.level = "debug"
else
    log.level = "info"
end

-- Expose Blocks in global scope for compatibility (optional)
_G.Blocks = Blocks

table.unpack = table.unpack or unpack

-- Helper: clamp camera horizontally
local function clamp_camera()
    local max_camera = Game.WORLD_WIDTH * Game.BLOCK_SIZE - Game.screen_width
    if max_camera < 0 then max_camera = 0 end
    Game.camera_x = math.max(0, math.min(Game.camera_x, max_camera))
end

local function regenerate_world()
    -- create or regenerate the world
    if not Game.world then
        Game.world = World(Game.seed)
    else
        Game.world:load()
    end

    -- let the world create and own the layer canvases (full-world)
    Game.world:create_canvases(Game.BLOCK_SIZE)

    -- create player instance before positioning
    if not Game.player then
        Game.player = Player()
    end

    Game.world:add_entity(Game.player)

    if not Game.player.px or Game.player.px < 1 or Game.player.px > Game.WORLD_WIDTH then
        Game.player.px = 50
    end
    local top = Game.world:get_surface(0, math.floor(Game.player.px)) or (Game.WORLD_HEIGHT - 1)
    Game.player.py = top - Game.player.height

    -- create UI canvas owned by main (covers screen size)
    if Game.ui_canvas and Game.ui_canvas.release then pcall(function() Game.ui_canvas:release() end) end
    Game.ui_canvas = love.graphics.newCanvas(Game.screen_width, Game.screen_height)
    Game.ui_canvas:setFilter("nearest", "nearest")

    clamp_camera()
end

function love.load()
    love.window.setMode(1280, 720, { resizable = true, minwidth = 640, minheight = 480 })
    love.window.setTitle("Lasagna")

    Game.screen_width = love.graphics.getWidth()
    Game.screen_height = love.graphics.getHeight()

    Game.seed = os.time()

    -- create player instance before world regen so regenerate_world can position it
    Game.player = Player()

    regenerate_world()

    log.info("Game loaded")
end

function love.resize(w, h)
    Game.screen_width = w
    Game.screen_height = h
    -- recreate UI canvas to match new screen size
    if Game.ui_canvas and Game.ui_canvas.release then pcall(function() Game.ui_canvas:release() end) end
    Game.ui_canvas = love.graphics.newCanvas(Game.screen_width, Game.screen_height)
    Game.ui_canvas:setFilter("nearest", "nearest")
    clamp_camera()
end

function love.keypressed(key)
    -- Backspace toggles debug mode at runtime
    if key == "backspace" then
        Game.debug = not Game.debug
        if Game.debug then
            log.level = "debug"
        else
            log.level = "info"
        end
        log.info("Debug mode: " .. tostring(Game.debug))
        return
    end

    if key == "q" then
        local old_z = Game.player.z
        Game.player.z = math.max(-1, Game.player.z - 1)
        local top = Game.world:get_surface(Game.player.z, math.floor(Game.player.px)) or (Game.WORLD_HEIGHT - 1)
        Game.player.py = top - Game.player.height
        Game.player.vy = 0
        if Game.player.z ~= old_z then
            log.info(string.format("Switched layer: %d -> %d", old_z, Game.player.z))
        end
    elseif key == "e" then
        local old_z = Game.player.z
        Game.player.z = math.min(1, Game.player.z + 1)
        local top = Game.world:get_surface(Game.player.z, math.floor(Game.player.px)) or (Game.WORLD_HEIGHT - 1)
        Game.player.py = top - Game.player.height
        Game.player.vy = 0
        if Game.player.z ~= old_z then
            log.info(string.format("Switched layer: %d -> %d", old_z, Game.player.z))
        end
    elseif key == "escape" then
        love.event.quit()
    elseif key == "space" or key == "up" then
        Game.player.intent = Game.player.intent or {}
        Game.player.intent.jump = true
    end
end

function love.wheelmoved(x, y)
    Game.player:wheelmoved(x, y)
end

function love.mousepressed(x, y, button, istouch, presses)
    if Game.player.placeAtMouse and (button == 2 or button == "r") then
        local ok, err, z_changed = Game.player:placeAtMouse(Game.world, Game.camera_x, Game.BLOCK_SIZE, x, y)
        if ok then
            -- World:set_block will call draw_column to update the layer canvas.
            log.info("Place succeeded:", tostring(err))
        else
            log.warn("Place failed:", tostring(err))
        end
    elseif Game.player.removeAtMouse and (button == 1 or button == "l") then
        local mouse_x, mouse_y = x, y
        local world_px = mouse_x + Game.camera_x
        local col = math.floor(world_px / Game.BLOCK_SIZE) + 1
        local row = math.floor(mouse_y / Game.BLOCK_SIZE) + 1
        col = math.max(1, math.min(Game.WORLD_WIDTH, col))
        row = math.max(1, math.min(Game.WORLD_HEIGHT, row))
        print(string.format("[DEBUG] Left click at screen(%d,%d) -> world col,row = %d,%d  player.z = %d", mouse_x, mouse_y, col, row, Game.player.z))
        local ok, err, z_changed = Game.player:removeAtMouse(Game.world, Game.camera_x, Game.BLOCK_SIZE, x, y)
        if ok then
            -- World:set_block will call draw_column to update the layer canvas.
            log.info("Remove succeeded:", tostring(err))
        else
            log.warn("Remove failed:", tostring(err))
        end
    end
end

function love.update(dt)
    Game.player:update(dt)
    Game.world:update(dt)

    Game.player.px = math.max(1, math.min(Game.WORLD_WIDTH - Game.player.width, Game.player.px))
    Game.camera_x = (Game.player.px + Game.player.width / 2) * Game.BLOCK_SIZE - Game.screen_width / 2
    clamp_camera()
end

function love.draw()
    -- World composes layer canvases + player + hud (World.draw uses self.canvases by default)
    Game.world:draw(Game.camera_x, nil, Game.player, Game.BLOCK_SIZE, Game.screen_width, Game.screen_height, Game.debug)

    -- UI canvas usage (main owns it). Draw UI into Game.ui_canvas, then composite.
    if Game.ui_canvas then
        love.graphics.push()
        love.graphics.setCanvas(Game.ui_canvas)
        love.graphics.clear(0,0,0,0)
        love.graphics.origin()

        if Game.player and Game.player.drawInventory then
            Game.player:drawInventory(Game.screen_width, Game.screen_height)
        end

        love.graphics.setCanvas()
        love.graphics.pop()

        love.graphics.push()
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(Game.ui_canvas, 0, 0)
        love.graphics.pop()
    end

    if Game.debug then
        local mx, my = 0, 0
        if love.mouse and love.mouse.getPosition then
            mx, my = love.mouse.getPosition()
        end
        local col = math.floor((mx + Game.camera_x) / Game.BLOCK_SIZE) + 1
        col = math.max(1, math.min(Game.WORLD_WIDTH, col))
        local by = math.floor(my / Game.BLOCK_SIZE) + 1
        by = math.max(1, math.min(Game.WORLD_HEIGHT, by))
        local layer_z = Game.player.z
        local block_type = Game.world:get_block_type(layer_z, col, by)
        local block_name = (type(block_type) == "table" and block_type.name) or tostring(block_type)

        local debug_lines = {}
        debug_lines[#debug_lines+1] = "DEBUG MODE: ON"
        debug_lines[#debug_lines+1] = string.format("Inventory selected: %d / %d (mouse wheel)", Game.player.inventory.selected, Game.player.inventory.slots)
        debug_lines[#debug_lines+1] = string.format("Mouse pixel: %.0f, %.0f", mx, my)
        debug_lines[#debug_lines+1] = string.format("World col,row: %d, %d", col, by)
        debug_lines[#debug_lines+1] = string.format("Layer (player): %d", layer_z)
        debug_lines[#debug_lines+1] = "Block: " .. block_name

        local padding = 6
        local line_h = 14
        local box_w = 420
        local box_h = #debug_lines * line_h + padding * 2
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 6, 6, box_w, box_h)
        love.graphics.setColor(1, 1, 1, 1)
        for i, ln in ipairs(debug_lines) do
            love.graphics.print(ln, 10, 6 + padding + (i-1) * line_h)
        end
        love.graphics.setColor(1,1,1,1)
    end
end