local Object = require("lib.object")
local Camera = require("camera")
local World = require("world.world")
local Player = require("entities.player")
local Blocks = require("data.blocks")
local Items = require("data.items")
local log = require("lib.log")

local Game = Object {
    -- window
    width = 0, height = 0,
    -- camera
    camera = nil,
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
    self.camera = Camera()
    self.mx, self.my = 0, 0
    self.width, self.height = love.graphics.getWidth(), love.graphics.getHeight()
    self.held_drops = {}  -- List of drops being held by right mouse button
    self.right_mouse_down = false
    self.left_mouse_down = false  -- Track left mouse state for continuous shooting
    self.grab_offset_x = 0  -- Initial mouse position when grabbing drops
    self.grab_offset_y = 0
    self.canvas = nil  -- Global canvas for drawing entities (player, items, bullets, drops, etc.)
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
    -- Recreate canvas with new dimensions
    self.canvas = nil
    -- Also mark all layers as dirty to recreate their canvases
    if self.world and self.world.layers then
        for z = C.LAYER_MIN, C.LAYER_MAX do
            if self.world.layers[z] then
                self.world.layers[z].canvas = nil
                self.world.layers[z]:mark_dirty()
            end
        end
    end
end

function Game:keypressed(key)
    if key == "backspace" then
        self.debug = not self.debug
        if self.debug then
            log.level = "debug"
        else
            log.level = "info"
        end
    elseif key == "k" and self.debug then
        -- Clear all drops when in debug mode
        if self.world and self.world.entities then
            local removed_count = 0
            for i = #self.world.entities, 1, -1 do
                local e = self.world.entities[i]
                if e.proto then  -- Check if it's a drop (has proto field)
                    table.remove(self.world.entities, i)
                    removed_count = removed_count + 1
                end
            end
            log.debug(string.format("Cleared %d drops", removed_count))
        end
    else
        -- Delegate player controls to Player
        self:player():keypressed(key)
    end
end

function Game:wheelmoved(x, y)
    self:player():wheelmoved(x, y)
end

function Game:mousemoved(x, y, dx, dy, istouch)
    self.mx, self.my = x, y
end

function Game:mousepressed(x, y, button, istouch, presses)
    local player = self:player()

    -- Check if inventory is open and handle inventory clicks
    if player.inventory.ui.open then
        player:inventory_pressed(x, y, button)
        return
    end

    if button == 1 or button == "l" then
        -- Left click: check if shooting or removing blocks
        if player:has_weapon_selected() then
            -- Weapon is selected - shoot immediately on press
            local cx = self.camera:get_x()
            local cy = self.camera:get_y()
            local world_x = (x + cx) / C.BLOCK_SIZE
            local world_y = (y + cy) / C.BLOCK_SIZE
            player:shoot_bullet(world_x, world_y)
            self.left_mouse_down = true
        elseif player.removeAtMouse then
            -- No weapon - regular block removal
            local ok, err, z_changed = player:removeAtMouse(x, y)
            if not ok then
                log.warn("Remove failed:", tostring(err))
            end
        end
    elseif button == 2 or button == "r" then
        -- Right click: check if placing block or grabbing drops

        -- Get selection area
        local cx = self.camera:get_x()
        local cy = self.camera:get_y()
        local world_px = x + cx
        local world_py = y + cy
        local col = math.floor(world_px / C.BLOCK_SIZE) + 1
        local row = math.floor(world_py / C.BLOCK_SIZE) + 1
        row = math.max(1, math.min(C.WORLD_HEIGHT, row))

        local size = player.selection_size
        local start_col = col
        local start_row = row

        if size > 1 then
            start_col = col - math.floor(size / 2)
            start_row = row - math.floor(size / 2)
        end

        -- Check if there are any drops in the selection area
        local drops_found = false
        local grab_col = world_px / C.BLOCK_SIZE
        local grab_row = world_py / C.BLOCK_SIZE

        for _, drop in ipairs(self.world.entities) do
            if drop.proto and drop.z == player.z then
                -- Check if drop is in selection area
                local drop_col = math.floor(drop.px)
                local drop_row = math.floor(drop.py)

                if drop_col >= start_col and drop_col < start_col + size and
                   drop_row >= start_row and drop_row < start_row + size then
                    -- Store the offset from grab position to drop position
                    local drop_info = {
                        drop = drop,
                        offset_x = drop.px - grab_col,
                        offset_y = drop.py - grab_row
                    }
                    table.insert(self.held_drops, drop_info)
                    drop.being_held = true
                    drops_found = true
                end
            end
        end

        -- If no drops found, try to place a block
        if not drops_found and player.placeAtMouse then
            local ok, err, z_changed = player:placeAtMouse(x, y)
            if not ok then
                log.warn("Place failed:", tostring(err))
            end
        else
            self.right_mouse_down = true
        end
    end
end

function Game:mousereleased(x, y, button, istouch, presses)
    local player = self:player()

    -- Check if inventory is open and handle inventory releases
    if player.inventory.ui.open then
        player:inventory_released(x, y, button)
        return
    end

    if button == 1 or button == "l" then
        -- Left mouse released
        self.left_mouse_down = false
    elseif button == 2 or button == "r" then
        -- Release all held drops
        for _, drop_info in ipairs(self.held_drops) do
            drop_info.drop.being_held = false
        end
        self.held_drops = {}
        self.right_mouse_down = false
    end
end

function Game:update(dt)
    -- Update camera to follow player
    local target_x = (self:player().px + self:player().width / 2) * C.BLOCK_SIZE
    local target_y = (self:player().py + self:player().height / 2) * C.BLOCK_SIZE
    self.camera:follow(target_x, target_y, self.width, self.height)

    -- Handle continuous shooting when weapon is selected and left mouse is held
    if self.left_mouse_down and self:player():has_weapon_selected() and not self:player().inventory.ui.open then
        local cx = self.camera:get_x()
        local cy = self.camera:get_y()
        local world_x = (self.mx + cx) / C.BLOCK_SIZE
        local world_y = (self.my + cy) / C.BLOCK_SIZE
        self:player():shoot_bullet(world_x, world_y)
    end

    -- Move held drops to mouse position
    if self.right_mouse_down and #self.held_drops > 0 then
        local cx = self.camera:get_x()
        local cy = self.camera:get_y()
        local world_px = self.mx + cx
        local world_py = self.my + cy
        local target_col = world_px / C.BLOCK_SIZE
        local target_row = world_py / C.BLOCK_SIZE

        for _, drop_info in ipairs(self.held_drops) do
            -- Move drop to mouse position + its stored offset
            drop_info.drop.px = target_col + drop_info.offset_x
            drop_info.drop.py = target_row + drop_info.offset_y
            drop_info.drop.vy = 0  -- No vertical velocity while held
        end
    end

    -- world entities ...
    self.world:update(dt)
end

function Game:drawFPS()
    if not self.world or not self.world.weather then return end
    local str = string.format("%d fps", love.timer.getFPS())
    local font = love.graphics.getFont()
    local text_height = font:getHeight()
    local padding = 10
    local bg_padding = 6
    local font = love.graphics.getFont()
    local text_width = font:getWidth(str)
    local text_height = font:getHeight()
    local x = padding
    local y = padding
    love.graphics.setColor(T.bg[1], T.bg[2], T.bg[3], (T.bg[4] or 1) * 0.5)
    love.graphics.rectangle("fill", x, y, text_width + bg_padding * 2, text_height + bg_padding * 2, 4, 4)
    love.graphics.setColor(T.fg[1], T.fg[2], T.fg[3], (T.fg[4] or 1) * 1)
    love.graphics.print(str, x + bg_padding, y + bg_padding)
end

function Game:drawInspector()
    if not self.world or not self.world.weather then return end
    local cx = self.camera:get_x()
    local cy = self.camera:get_y()
    local col = math.floor((self.mx + cx) / C.BLOCK_SIZE) + 1
    local row = math.max(1, math.min(C.WORLD_HEIGHT, math.floor((self.my + cy) / C.BLOCK_SIZE) + 1))
    local lz = self:player().z
    local block_type = self.world:get_block_type(lz, col, row)
    local str = (type(block_type) == "table" and block_type.name) or tostring(block_type)
    local padding = 10
    local bg_padding = 6
    local font = love.graphics.getFont()
    local text_width = font:getWidth(str)
    local text_height = font:getHeight()
    local x = self.width / 2 - text_width / 2 - padding / 2
    local y = padding
    love.graphics.setColor(T.bg[1], T.bg[2], T.bg[3], (T.bg[4] or 1) * 0.5)
    love.graphics.rectangle("fill", x, y, text_width + bg_padding * 2, text_height + bg_padding * 2, 4, 4)
    love.graphics.setColor(T.fg[1], T.fg[2], T.fg[3], (T.fg[4] or 1) * 1)
    love.graphics.print(str, x + bg_padding, y + bg_padding)
end

function Game:drawClock()
    if not self.world or not self.world.weather then return end
    local str = self.world.weather:get_time_string()
    local padding = 10
    local bg_padding = 6
    local font = love.graphics.getFont()
    local text_width = font:getWidth(str)
    local text_height = font:getHeight()
    local x = self.width - text_width - padding - bg_padding * 2
    local y = padding
    love.graphics.setColor(T.bg[1], T.bg[2], T.bg[3], (T.bg[4] or 1) * 0.5)
    love.graphics.rectangle("fill", x, y, text_width + bg_padding * 2, text_height + bg_padding * 2, 4, 4)
    love.graphics.setColor(T.fg[1], T.fg[2], T.fg[3], (T.fg[4] or 1) * 1)
    love.graphics.print(str, x + bg_padding, y + bg_padding)
end

function Game:drawHUD()
    self:drawFPS()
    self:drawInspector()
    self:drawClock()
end

function Game:draw()
    -- Draw world (terrain layers only)
    self.world:draw()

    -- Create entity canvas if it doesn't exist or has wrong size
    if not self.canvas or self.canvas:getWidth() ~= self.width or self.canvas:getHeight() ~= self.height then
        self.canvas = love.graphics.newCanvas(self.width, self.height)
    end

    -- Draw all entities to canvas
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()

    -- Draw entities (drops, bullets, rockets, etc.)
    self.world:draw_entities()

    -- Draw player
    self:player():draw()

    -- Reset render target
    love.graphics.setCanvas()

    -- Draw the entity canvas to screen
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvas, 0, 0)

    -- Draw HUD on top (no canvas needed for UI)
    self:player():drawInventory() -- bottom-center
    self:drawHUD() -- top
    self:player():drawGhost() -- at mouse
    -- inventory screen (if open)
    self:player():drawInventoryScreen()
    -- debug
    if self.debug then
        local cx = self.camera:get_x()
        local col = math.floor((self.mx + cx) / C.BLOCK_SIZE) + 1
        local by = math.max(1, math.min(C.WORLD_HEIGHT, math.floor(self.my / C.BLOCK_SIZE) + 1))
        local lz = self:player().z
        local debug_lines = {}
        debug_lines[#debug_lines+1] = string.format("FPS/Delta: %d %f", love.timer.getFPS(), love.timer.getAverageDelta())
        debug_lines[#debug_lines+1] = string.format("Layer: %d", lz)
        debug_lines[#debug_lines+1] = string.format("Mouse: %.0f,%.0f", self.mx, self.my)
        debug_lines[#debug_lines+1] = string.format("Block: %d,%d", col, by)
        local padding = 6
        local line_h = 14
        local box_w = 420
        local box_h = #debug_lines * line_h + padding * 2
        love.graphics.setColor(1, 0, 0, 1)
        for i, ln in ipairs(debug_lines) do
            love.graphics.print(ln, 10, padding * padding + padding + (i-1) * line_h)
        end
        -- love.graphics.setColor(T.fg[1], T.fg[2], T.fg[3], (T.fg[4] or 1) * 1)
    end
end

return Game
