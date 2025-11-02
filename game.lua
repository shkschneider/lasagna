local Object = require("lib.object")
local World = require("world.world")
local Player = require("entities.player")
local Blocks = require("world.blocks")
local log = require("lib.log")

local Game = Object {
    -- window
    width = 0, height = 0,
    -- camera
    cx, cy = 0, 0,
    -- mouse
    mx, my = 0, 0,
    -- ...
    player = function (self)
        return self.world.entities[1]
    end,
}

function Game:new()
    log.info("New Game")
    -- configure logger level from debug flag (off by default)
    self.debug = os.getenv("DEBUG") == "true"
    if self.debug then
        log.level = "debug"
    else
        log.level = "info"
    end
    -- UI / runtime state
    self.world = nil
    self.cx = 0
    self.width, self.height = love.graphics.getWidth(), love.graphics.getHeight()
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
    local top = self.world:get_surface(0, math.floor(self:player().px)) or (C.WORLD_HEIGHT - 1)
    self:player().py = top - self:player().height
    log.info(string.format("Game[%d] loaded", seed))
end

function Game:resize(width, height)
    self.width, self.height = love.graphics.getWidth(), love.graphics.getHeight()
    log.info(string.format("Resized: %dx%d", self.width, self.height))
end

function Game:keypressed(key)
    if key == "backspace" then
        self.debug = not self.debug
        if self.debug then
            log.level = "debug"
        else
            log.level = "info"
        end
    else
        -- Delegate player controls to Player
        self:player():keypressed(key)
    end
end

function Game:wheelmoved(x, y)
    self:player():wheelmoved(x, y)
end

function Game:mousepressed(x, y, button, istouch, presses)
    if self:player().placeAtMouse and (button == 2 or button == "r") then
        local ok, err, z_changed = self:player():placeAtMouse(x, y)
        if not ok then
            log.warn("Place failed:", tostring(err))
        end
    elseif self:player().removeAtMouse and (button == 1 or button == "l") then
        local ok, err, z_changed = self:player():removeAtMouse(x, y)
        if not ok then
            log.warn("Remove failed:", tostring(err))
        end
    end
end

function Game:update(dt)
    self.world:update(dt)
    self.cx = (self:player().px + self:player().width / 2) * C.BLOCK_SIZE - self.width / 2
end

function Game:drawTimeHUD()
    if not self.world or not self.world.weather then return end
    
    local time_str = self.world.weather:get_time_string()
    local padding = 10
    local bg_padding = 6
    
    -- Measure text size
    local font = love.graphics.getFont()
    local text_width = font:getWidth(time_str)
    local text_height = font:getHeight()
    
    -- Position in top-right
    local x = self.width - text_width - padding - bg_padding * 2
    local y = padding
    
    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", x, y, text_width + bg_padding * 2, text_height + bg_padding * 2, 4, 4)
    
    -- Draw time text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(time_str, x + bg_padding, y + bg_padding)
end

function Game:draw()
    self.world:draw()
    self.mx, self.my = love.mouse.getPosition()
    self:player():draw()
    self:player():drawInventory()
    self:player():drawGhost()
    -- Draw UI/HUD
    self:drawTimeHUD()
    if self.debug then
        local col = math.floor((self.mx + self.cx) / C.BLOCK_SIZE) + 1
        local by = math.max(1, math.min(C.WORLD_HEIGHT, math.floor(self.my / C.BLOCK_SIZE) + 1))
        local lz = self:player().z
        local block_type = self.world:get_block_type(lz, col, by)
        local block_name = (type(block_type) == "table" and block_type.name) or tostring(block_type)
        local debug_lines = {}
        debug_lines[#debug_lines+1] = "[DEBUG]"
        debug_lines[#debug_lines+1] = string.format("Inventory selected: %d / %d (mouse wheel)", self:player().inventory.selected, self:player().inventory.slots)
        debug_lines[#debug_lines+1] = string.format("Mouse pixel: %.0f, %.0f", self.mx, self.my)
        debug_lines[#debug_lines+1] = string.format("World col,row: %d, %d", col, by)
        debug_lines[#debug_lines+1] = string.format("Layer (player): %d", lz)
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
