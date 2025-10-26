--[[
    Main application (uses world.lua and player.lua, Blocks moved to blocks.lua)
    - Blocks table is now in blocks.lua and required here.
    - Player drawing uses the Player module's color (player is not a world block).
    - HUD/status text only shown in debug overlay; seed moved into debug overlay as second line.
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

    -- Player will be created from player.lua
    player = nil,

    -- Debug flag (start in debug mode by default for now)
    debug = true,
}

-- Require modules and data
local World = require("world")
local Player = require("player")
local Blocks = require("blocks") -- world block palette (player removed from Blocks)

-- Expose Blocks in global scope for compatibility (optional)
_G.Blocks = Blocks

-- compatibility for unpack across Lua versions (Lua 5.2+ vs 5.1 / LuaJIT)
local unpack = table.unpack or unpack or function(t)
    return t[1], t[2], t[3], t[4]
end

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
        -- Use the World:draw helper to render the layer into the canvas
        Game.world:draw(z, canvas, Blocks, Game.BLOCK_SIZE)
    end

    -- Set player starting position (on default layer grass) if player px is valid,
    -- otherwise fallback to center column (50)
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

    Game.seed = getSeedFromArgs() or os.time()

    local dbg_env = os.getenv and os.getenv("DEBUG")
    if not Game.debug and dbg_env then
        local v = tostring(dbg_env):lower()
        if v == "1" or v == "true" or v == "yes" then Game.debug = true end
    end

    -- create player instance before world regen so regenerate_world can position it
    Game.player = Player.new{ px = 50, z = 0 }

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
    -- Build a simple input table for the player
    local input = {
        left = love.keyboard.isDown("a"),
        right = love.keyboard.isDown("d"),
        -- jump handled via keypressed space/up to start jump, but we'll still allow continuous press:
        jump = false
    }

    -- Player update (world is pure logic)
    Game.player:update(dt, Game.world, input)

    -- Clamp player x inside world (Player already clamps, but keep as safety)
    Game.player.px = math.max(1, math.min(Game.WORLD_WIDTH - Game.player.width, Game.player.px))

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
            -- delegate player drawing to the Player module
            Game.player:draw(Game.BLOCK_SIZE, Game.camera_x)
        end
    end

    -- HUD and debug overlay
    love.graphics.origin()

    -- Debug UI (top-left) when debug mode is enabled (seed is now part of debug_lines)
    if Game.debug then
        local mx, my = love.mouse.getPosition()
        -- convert mouse pixel -> world block column and row
        local col = math.floor((mx + Game.camera_x) / Game.BLOCK_SIZE) + 1
        col = math.max(1, math.min(Game.WORLD_WIDTH, col))
        local by = math.floor(my / Game.BLOCK_SIZE) + 1
        by = math.max(1, math.min(Game.WORLD_HEIGHT, by))

        local layer_z = Game.player.z -- use player layer for "current" context
        local block_type = get_block_type_at(layer_z, col, by)

        -- Build debug text (seed is second line)
        local debug_lines = {}
        debug_lines[#debug_lines+1] = "DEBUG MODE: ON (Backspace to toggle)"
        debug_lines[#debug_lines+1] = "Seed: " .. tostring(Game.seed)
        debug_lines[#debug_lines+1] = string.format("Mouse pixel: %.0f, %.0f", mx, my)
        debug_lines[#debug_lines+1] = string.format("World col,row: %d, %d", col, by)
        debug_lines[#debug_lines+1] = string.format("Layer (player): %d", layer_z)
        debug_lines[#debug_lines+1] = "Block: " .. tostring(block_type)
        debug_lines[#debug_lines+1] = "Press Delete to reset world"

        -- draw semi-opaque background box for readability
        local padding = 6
        local line_h = 14
        local box_w = 280
        local box_h = #debug_lines * line_h + padding * 2
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 6, 6, box_w, box_h)
        love.graphics.setColor(1, 1, 1, 1)
        for i, ln in ipairs(debug_lines) do
            love.graphics.print(ln, 10, 6 + padding + (i-1) * line_h)
        end
    end
end