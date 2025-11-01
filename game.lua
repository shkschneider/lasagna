local Object = require("lib.object")
local World = require("world.world")
local Player = require("entities.player")
local Blocks = require("world.blocks")
local log = require("lib.log")

local Game = Object {
    NAME = "Lasagna",

    -- world geometry & rendering
    BLOCK_SIZE = 16,
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
}

function Game:new()
    -- configure logger level from debug flag (off by default
    self.debug = os.getenv("DEBUG") == "true"
    if self.debug then
        log.level = "debug"
    else
        log.level = "info"
    end
    -- UI / runtime state
    self.world = nil
    self.camera_x = 0
    self.screen_width = love.graphics.getWidth()
    self.screen_height = love.graphics.getHeight()
    self.canvas = nil
end

function Game:load(seed)
    -- seed
    assert(seed)
    math.randomseed(seed)
    -- world
    if not self.world then
        self.world = World(seed)
    end
    self.world:load()
    -- player - spawn at a reasonable position
    if not self:player().px or self:player().px < -1000 or self:player().px > 1000 then
        self:player().px = 50
    end
    local top = self.world:get_surface(0, math.floor(self:player().px)) or (self.WORLD_HEIGHT - 1)
    self:player().py = top - self:player().height
    -- canvas
    self:resize(love.graphics.getWidth(), love.graphics.getHeight())
    log.info("Game loaded: " .. tostring(seed))
end

function Game:player()
    return self.world.entities[1]
end

function Game:resize(width, height)
    self.screen_width = width
    self.screen_height = height
    if self.canvas and self.canvas.release then pcall(function() self.canvas:release() end) end
    self.canvas = love.graphics.newCanvas(self.screen_width, self.screen_height)
    self.canvas:setFilter("nearest", "nearest")
end

function Game:keypressed(key)
    if key == "backspace" then
        self.debug = not self.debug
        if self.debug then
            log.level = "debug"
        else
            log.level = "info"
        end
    elseif key == "q" then
        local old_z = self:player().z
        self:player().z = math.max(-1, self:player().z - 1)
        local top = self.world:get_surface(self:player().z, math.floor(self:player().px)) or (self.WORLD_HEIGHT - 1)
        self:player().py = top - self:player().height
        self:player().vy = 0
        if self:player().z ~= old_z then
            log.info(string.format("Switched layer: %d -> %d", old_z, self:player().z))
        end
    elseif key == "e" then
        local old_z = self:player().z
        self:player().z = math.min(1, self:player().z + 1)
        local top = self.world:get_surface(self:player().z, math.floor(self:player().px)) or (self.WORLD_HEIGHT - 1)
        self:player().py = top - self:player().height
        self:player().vy = 0
        if self:player().z ~= old_z then
            log.info(string.format("Switched layer: %d -> %d", old_z, self:player().z))
        end
    elseif key == "space" or key == "up" then
        self:player().intent = self:player().intent or {}
        self:player().intent.jump = true
    end
end

function Game:wheelmoved(x, y)
    self:player():wheelmoved(x, y)
end

function Game:mousepressed(x, y, button, istouch, presses)
    if self:player().placeAtMouse and (button == 2 or button == "r") then
        local ok, err, z_changed = self:player():placeAtMouse(self.world, self.camera_x, self.BLOCK_SIZE, x, y)
        if not ok then
            log.warn("Place failed:", tostring(err))
        end
    elseif self:player().removeAtMouse and (button == 1 or button == "l") then
        local mouse_x, mouse_y = x, y
        local world_px = mouse_x + self.camera_x
        local col = math.floor(world_px / self.BLOCK_SIZE) + 1
        local row = math.floor(mouse_y / self.BLOCK_SIZE) + 1
        row = math.max(1, math.min(self.WORLD_HEIGHT, row))
        local ok, err, z_changed = self:player():removeAtMouse(self.world, self.camera_x, self.BLOCK_SIZE, x, y)
        if not ok then
            log.warn("Remove failed:", tostring(err))
        end
    end
end

function Game:update(dt)
    self.world:update(dt)
    self:player():update(dt)
    self.camera_x = (self:player().px + self:player().width / 2) * self.BLOCK_SIZE - self.screen_width / 2
end

function Game:draw()
    self.world:draw(self.camera_x, nil, self:player(), self.BLOCK_SIZE, self.screen_width, self.screen_height, self.debug)
    if self.canvas then
        love.graphics.push()
        love.graphics.setCanvas(self.canvas)
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.origin()
        self:player():drawInventory(self.screen_width, self.screen_height)
        love.graphics.setCanvas()
        love.graphics.pop()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.canvas, 0, 0)
    end
    if self.debug then
        local mx, my = 0, 0
        if love.mouse and love.mouse.getPosition then
            mx, my = love.mouse.getPosition()
        end
        local col = math.floor((mx + self.camera_x) / self.BLOCK_SIZE) + 1
        local by = math.floor(my / self.BLOCK_SIZE) + 1
        by = math.max(1, math.min(self.WORLD_HEIGHT, by))
        local layer_z = self:player().z
        local block_type = self.world:get_block_type(layer_z, col, by)
        local block_name = (type(block_type) == "table" and block_type.name) or tostring(block_type)
        local debug_lines = {}
        debug_lines[#debug_lines+1] = "[DEBUG]"
        debug_lines[#debug_lines+1] = string.format("Inventory selected: %d / %d (mouse wheel)", self:player().inventory.selected, self:player().inventory.slots)
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

return Game
