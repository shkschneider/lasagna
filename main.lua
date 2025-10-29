-- Main application (updated to use prototypes in world.tiles and Player()/World.new(seed) defaults)

-- Global game table
Game = {
    BLOCK_SIZE = 16,
    WORLD_WIDTH = 500,
    WORLD_HEIGHT = 100,
    GRAVITY = 20,

    MOVE_ACCEL = 60,
    MAX_SPEED = 6,
    GROUND_FRICTION = 30,
    AIR_ACCEL_MULT = 0.35,
    AIR_FRICTION = 1.5,

    RUN_SPEED_MULT = 1.6,
    RUN_ACCEL_MULT = 1.2,

    CROUCH_DECEL = 120,
    CROUCH_MAX_SPEED = 3,

    JUMP_SPEED = -10,
    STEP_HEIGHT = 1,

    DIRT_THICKNESS = 10,
    STONE_THICKNESS = 10,

    LAYER_BASE_HEIGHTS = { [-1] = 20, [0] = 30, [1] = 40 },

    world = nil,
    canvases = {},
    camera_x = 0,
    screen_width = 0,
    screen_height = 0,
    seed = nil,

    player = nil,

    debug = true,
}

local World = require("world")
local Player = require("player")
local Blocks = require("blocks")
local log = require("lib.log")

if Game.debug then
    log.level = "debug"
else
    log.level = "info"
end

_G.Blocks = Blocks
table.unpack = table.unpack or unpack

local function clamp_camera()
    local max_camera = Game.WORLD_WIDTH * Game.BLOCK_SIZE - Game.screen_width
    if max_camera < 0 then max_camera = 0 end
    Game.camera_x = math.max(0, math.min(Game.camera_x, max_camera))
end

local function regenerate_world()
    if not Game.world then
        Game.world = World.new(Game.seed)
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
        Game.player = Player()
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
        local ok, err, z_changed = Game.player:placeAtMouse(Game.world, Game.camera_x, Game.BLOCK_SIZE, x, y)
        if ok then
            local target_z = z_changed or Game.player.z
            if Game.world and Game.canvases and Game.canvases[target_z] then
                Game.world:draw(target_z, Game.canvases[target_z], Blocks, Game.BLOCK_SIZE)
            end
            log.info("Place succeeded:", tostring(err))
        else
            log.warn("Place failed:", tostring(err))
        end
    elseif Game.player and Game.player.removeAtMouse and (button == 1 or button == "l") then
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
                Game.world:draw(target_z, Game.canvases[target_z], Blocks, Game.BLOCK_SIZE)
            end
            log.info("Remove succeeded:", tostring(err))
        else
            log.warn("Remove failed:", tostring(err))
        end
    end
end

function love.update(dt)
    -- Build input table is no longer passed; Player:update reads input directly
    Game.player:update(dt)

    Game.player.px = math.max(1, math.min(Game.WORLD_WIDTH - Game.player.width, Game.player.px))
    Game.camera_x = (Game.player.px + Game.player.width / 2) * Game.BLOCK_SIZE - Game.screen_width / 2
    clamp_camera()
end

-- Draw a layer by blitting its canvas, now with per-layer dimming below player
local function draw_layer(z)
    local canvas = Game.canvases[z]
    if not canvas then return end
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(-Game.camera_x, 0)

    local alpha = 1
    if Game.player and type(Game.player.z) == "number" and z < Game.player.z then
        local depth = Game.player.z - z
        alpha = 1 - 0.25 * depth
        if alpha < 0 then alpha = 0 end
    end

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(canvas, 0, 0)
    love.graphics.pop()
    love.graphics.setColor(1,1,1,1)
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
    end
end