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
    canvases = {},
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
        -- create a World instance by calling the prototype
        Game.world = World(Game.seed)
    else
        Game.world:load()
    end

    local canvas_w = Game.WORLD_WIDTH * Game.BLOCK_SIZE
    local canvas_h = Game.WORLD_HEIGHT * Game.BLOCK_SIZE

    for z = -1, 1 do
        local canvas = love.graphics.newCanvas(canvas_w, canvas_h)
        canvas:setFilter("nearest", "nearest")
        Game.canvases[z] = canvas
        -- legacy single-layer draw: use draw_layer
        if Game.world and Game.world.draw_layer then
            Game.world:draw_layer(z, canvas, Blocks, Game.BLOCK_SIZE)
        end
    end

    if not Game.player then
        -- create player instance by calling the prototype
        Game.player = Player()
    end

    -- register player with world so World.update will simulate it
    if Game.world then
        Game.world:add_entity(Game.player)
    end

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

    Game.seed = os.time()

    -- create player instance before world regen so regenerate_world can position it
    Game.player = Player()

    regenerate_world()

    log.info("Game loaded")
end

function love.resize(w, h)
    Game.screen_width = w
    Game.screen_height = h
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
        -- set jump intent; World.update will consume it (one-shot)
        if Game.player then
            Game.player.intent = Game.player.intent or {}
            Game.player.intent.jump = true
        end
    end
end

function love.wheelmoved(x, y)
    if Game.player and Game.player.wheelmoved then
        Game.player:wheelmoved(x, y)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if Game.player and Game.player.placeAtMouse and (button == 2 or button == "r") then
        local ok, err, z_changed = Game.player:placeAtMouse(Game.world, Game.camera_x, Game.BLOCK_SIZE, x, y)
        if ok then
            local target_z = z_changed or Game.player.z
            if Game.world and Game.canvases and Game.canvases[target_z] then
                -- re-draw only affected layer
                if Game.world.draw_layer then
                    Game.world:draw_layer(target_z, Game.canvases[target_z], Blocks, Game.BLOCK_SIZE)
                end
            end
            log.info("Place succeeded:", tostring(err))
        else
            log.warn("Place failed:", tostring(err))
        end
    elseif Game.player and Game.player.removeAtMouse and (button == 1 or button == "l") then
        -- debug: compute column/row and log layer
        local mouse_x, mouse_y = x, y
        local world_px = mouse_x + Game.camera_x
        local col = math.floor(world_px / Game.BLOCK_SIZE) + 1
        local row = math.floor(mouse_y / Game.BLOCK_SIZE) + 1
        col = math.max(1, math.min(Game.WORLD_WIDTH, col))
        row = math.max(1, math.min(Game.WORLD_HEIGHT, row))
        print(string.format("[DEBUG] Left click at screen(%d,%d) -> world col,row = %d,%d  player.z = %d", mouse_x, mouse_y, col, row, Game.player.z))
        local ok, err, z_changed = Game.player:removeAtMouse(Game.world, Game.camera_x, Game.BLOCK_SIZE, x, y)
        if ok then
            local target_z = z_changed or Game.player.z
            if Game.world and Game.canvases and Game.canvases[target_z] then
                if Game.world.draw_layer then
                    Game.world:draw_layer(target_z, Game.canvases[target_z], Blocks, Game.BLOCK_SIZE)
                end
            end
            log.info("Remove succeeded:", tostring(err))
        else
            log.warn("Remove failed:", tostring(err))
        end
    end
end

function love.update(dt)
    -- Player still reads input and sets intent
    if Game.player and Game.player.update then
        Game.player:update(dt)
    end

    -- World applies physics & collision to registered entities
    if Game.world and Game.world.update then
        Game.world:update(dt)
    end

    Game.player.px = math.max(1, math.min(Game.WORLD_WIDTH - Game.player.width, Game.player.px))
    Game.camera_x = (Game.player.px + Game.player.width / 2) * Game.BLOCK_SIZE - Game.screen_width / 2
    clamp_camera()
end

function love.draw()
    -- Full-scene draw using World:draw (composes canvases + player + HUD)
    if Game.world and Game.world.draw then
        Game.world:draw(Game.camera_x, Game.canvases, Game.player, Game.BLOCK_SIZE, Game.screen_width, Game.screen_height, Game.debug)
    end

    -- Debug overlay — moved here from world.draw so UI remains within LÖVE callbacks
    if Game.debug and Game.world then
        local mx, my = 0, 0
        if love.mouse and love.mouse.getPosition then
            mx, my = love.mouse.getPosition()
        end
        local col = math.floor((mx + Game.camera_x) / Game.BLOCK_SIZE) + 1
        col = math.max(1, math.min(Game.WORLD_WIDTH, col))
        local by = math.floor(my / Game.BLOCK_SIZE) + 1
        by = math.max(1, math.min(Game.WORLD_HEIGHT, by))
        local layer_z = Game.player and Game.player.z or 0
        local block_type = Game.world:get_block_type(layer_z, col, by)
        local block_name = (type(block_type) == "table" and block_type.name) or tostring(block_type)

        local debug_lines = {}
        debug_lines[#debug_lines+1] = "DEBUG MODE: ON"
        if Game.player and Game.player.inventory then
            debug_lines[#debug_lines+1] = string.format("Inventory selected: %d / %d (mouse wheel)", Game.player.inventory.selected, Game.player.inventory.slots)
        end
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