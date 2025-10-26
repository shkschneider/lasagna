-- Main application (updated input mapping: crouch only on lctrl, run only on lshift)
--
-- This is the project entrypoint. I updated the input table so:
--  - crouch is true only when left Ctrl ("lctrl") is held (NOT rctrl or generic "ctrl")
--  - run is true only when left Shift ("lshift") is held (NOT rshift or generic "shift")
--
-- The rest of the file is the same as the previous main.lua you were using (world/player setup,
-- logging, rendering, etc.). Replace your existing main.lua with this file to apply the input changes.

-- Global game table
Game = {
    -- Constants (UPPERCASE)
    BLOCK_SIZE = 16,
    WORLD_WIDTH = 500,
    WORLD_HEIGHT = 100,
    GRAVITY = 20,    -- blocks / second^2

    -- Movement tuning (smooth accel / friction)
    MOVE_ACCEL = 60, -- blocks / second^2 (horizontal accel on ground)
    MAX_SPEED = 6,   -- blocks / second (base horizontal velocity)
    GROUND_FRICTION = 30, -- deceleration when no input and on ground
    AIR_ACCEL_MULT = 0.35, -- fraction of MOVE_ACCEL available in air
    AIR_FRICTION = 1.5, -- small deceleration in air when no input

    -- sprint / run tuning (Shift)
    RUN_SPEED_MULT = 1.6, -- multiplier to MAX_SPEED when running
    RUN_ACCEL_MULT = 1.2, -- multiplier to MOVE_ACCEL when running

    -- crouch tuning
    CROUCH_DECEL = 120,
    CROUCH_MAX_SPEED = 3,

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

    -- Player will be created from player.lua
    player = nil,

    -- Debug flag
    debug = true,
}

-- Require modules and data
local World = require("world")
local Player = require("player")
local Blocks = require("blocks")

-- logging and utilities
local log = require("lib.log")
local classic = require("lib.classic")

-- configure logger level from Game.debug
if Game.debug then
    log.level = "debug"
else
    log.level = "info"
end

-- Expose Blocks in global scope for compatibility (optional)
_G.Blocks = Blocks

-- compatibility for unpack across Lua versions (Lua 5.2+ vs 5.1 / LuaJIT)
local unpack = table.unpack or unpack or function(t) return t[1], t[2], t[3], t[4] end

-- Helper: clamp camera horizontally
local function clamp_camera()
    local max_camera = Game.WORLD_WIDTH * Game.BLOCK_SIZE - Game.screen_width
    if max_camera < 0 then max_camera = 0 end
    Game.camera_x = math.max(0, math.min(Game.camera_x, max_camera))
end

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
        Game.world:draw(z, canvas, Blocks, Game.BLOCK_SIZE)
    end

    if not Game.player then
        Game.player = Player.new{ px = 50, z = 0 }
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
    Game.player = Player.new{ px = 50, z = 0 }

    regenerate_world()

    log.info("Game loaded")
end

function love.resize(w, h)
    Game.screen_width = w
    Game.screen_height = h
    clamp_camera()
end

function love.keypressed(key)
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
        if Game.player.on_ground then
            Game.player.vy = Game.JUMP_SPEED
            Game.player.on_ground = false
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
        local ok, err = Game.player:placeAtMouse(Game.world, Game.camera_x, Game.BLOCK_SIZE, x, y)
        if ok then
            if Game.world and Game.canvases and Game.canvases[Game.player.z] then
                Game.world:draw(Game.player.z, Game.canvases[Game.player.z], Blocks, Game.BLOCK_SIZE)
            end
            log.info("Place succeeded:", tostring(err))
        else
            log.warn("Place failed:", tostring(err))
        end
    elseif Game.player and Game.player.removeAtMouse and (button == 1 or button == "l") then
        local ok, err = Game.player:removeAtMouse(Game.world, Game.camera_x, Game.BLOCK_SIZE, x, y)
        if ok then
            if Game.world and Game.canvases and Game.canvases[Game.player.z] then
                Game.world:draw(Game.player.z, Game.canvases[Game.player.z], Blocks, Game.BLOCK_SIZE)
            end
            log.info("Remove succeeded:", tostring(err))
        else
            log.warn("Remove failed:", tostring(err))
        end
    end
end

function love.update(dt)
    -- Build input table; note the keys for crouch/run are intentionally strict:
    -- crouch only using left Ctrl ("lctrl"), run only using left Shift ("lshift")
    local input = {
        left = love.keyboard.isDown("a"),
        right = love.keyboard.isDown("d"),
        jump = false,
        crouch = love.keyboard.isDown("lctrl"), -- only left ctrl triggers crouch
        run = love.keyboard.isDown("lshift"),   -- only left shift triggers run
    }

    Game.player:update(dt, Game.world, input)

    Game.player.px = math.max(1, math.min(Game.WORLD_WIDTH - Game.player.width, Game.player.px))
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

local function get_block_type_at(z, x, by)
    if not Game.world then return "out" end
    return Game.world:get_block_type(z, x, by)
end

function love.draw()
    for z = -1, Game.player.z do
        draw_layer(z)
        if z == Game.player.z then
            Game.player:draw(Game.BLOCK_SIZE, Game.camera_x)
        end
    end

    love.graphics.origin()

    if Game.player and Game.player.drawInventory then
        Game.player:drawInventory(Game.screen_width, Game.screen_height)
    end
    if Game.player and Game.player.drawGhost then
        Game.player:drawGhost(Game.world, Game.camera_x, Game.BLOCK_SIZE)
    end

    if Game.debug then
        local mx, my = love.mouse.getPosition()
        local col = math.floor((mx + Game.camera_x) / Game.BLOCK_SIZE) + 1
        col = math.max(1, math.min(Game.WORLD_WIDTH, col))
        local by = math.floor(my / Game.BLOCK_SIZE) + 1
        by = math.max(1, math.min(Game.WORLD_HEIGHT, by))
        local layer_z = Game.player.z
        local block_type = get_block_type_at(layer_z, col, by)

        local debug_lines = {}
        debug_lines[#debug_lines+1] = "DEBUG MODE: ON"
        debug_lines[#debug_lines+1] = string.format("Inventory selected: %d / %d (mouse wheel)", Game.player.inventory.selected, Game.player.inventory.slots)
        debug_lines[#debug_lines+1] = string.format("Mouse pixel: %.0f, %.0f", mx, my)
        debug_lines[#debug_lines+1] = string.format("World col,row: %d, %d", col, by)
        debug_lines[#debug_lines+1] = string.format("Layer (player): %d", layer_z)
        debug_lines[#debug_lines+1] = "Block: " .. tostring(block_type)

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
    end
end