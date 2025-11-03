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
    -- shaders
    player_shader = nil,
    sun_shader = nil,
    combined_shader = nil,
    -- surface map for occlusion
    surface_canvas = nil,
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
    -- Load shaders
    self.player_shader = love.graphics.newShader("shaders/player.glsl")
    self.sun_shader = love.graphics.newShader("shaders/sun.glsl")
    self.combined_shader = love.graphics.newShader("shaders/combined.glsl")
    -- Create surface canvas for occlusion
    self.surface_canvas = love.graphics.newCanvas(self.width, self.height)
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
    self.width, self.height = width, height
    -- Recreate surface canvas on resize
    if self.surface_canvas then
        self.surface_canvas:release()
    end
    self.surface_canvas = love.graphics.newCanvas(width, height)
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

function Game:mousemoved(x, y, dx, dy, istouch)
    self.mx, self.my = x, y
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
    -- Update camera to follow player
    local target_x = (self:player().px + self:player().width / 2) * C.BLOCK_SIZE
    local target_y = 0
    self.camera:follow(target_x, target_y, self.width, self.height)
    -- world entities ...
    self.world:update(dt)
end

function Game:drawTimeHUD()
    if not self.world or not self.world.weather then return end
    local time_str = self.world.weather:get_time_string()
    local padding = 10
    local bg_padding = 6
    local font = love.graphics.getFont()
    local text_width = font:getWidth(time_str)
    local text_height = font:getHeight()
    local x = self.width - text_width - padding - bg_padding * 2
    local y = padding
    love.graphics.setColor(T.bg[1], T.bg[2], T.bg[3], (T.bg[4] or 1) * 0.5)
    love.graphics.rectangle("fill", x, y, text_width + bg_padding * 2, text_height + bg_padding * 2, 4, 4)
    love.graphics.setColor(T.fg[1], T.fg[2], T.fg[3], (T.fg[4] or 1) * 1)
    love.graphics.print(time_str, x + bg_padding, y + bg_padding)
end

function Game:get_sun_params()
    if not self.world or not self.world.weather then
        return 0.5, 0.0  -- Default: mid-day, no angle
    end
    
    local hours, minutes = self.world.weather:get_time_24h()
    local time_decimal = hours + (minutes / 60.0)
    
    local sun_intensity, sun_angle
    
    if time_decimal >= 6 and time_decimal < 12 then
        -- Morning: 06:00 to 12:00 (sunrise to noon)
        local t = (time_decimal - 6) / 6
        sun_intensity = 0.1 + (t * 0.9)  -- 0.1 to 1.0
        sun_angle = -1.57 + (t * 1.57)   -- -90° to 0° (rising from east)
    elseif time_decimal >= 12 and time_decimal < 18 then
        -- Afternoon: 12:00 to 18:00 (noon to sunset)
        local t = (time_decimal - 12) / 6
        sun_intensity = 1.0 - (t * 0.9)  -- 1.0 to 0.1
        sun_angle = t * 1.57             -- 0° to 90° (setting to west)
    else
        -- Night: 18:00 to 06:00
        sun_intensity = 0.05  -- Very low ambient light at night
        sun_angle = 0.0
    end
    
    return sun_intensity, sun_angle
end

function Game:render_surface_map()
    -- Render solid blocks to a canvas for occlusion calculations
    if not self.surface_canvas then return end
    
    love.graphics.setCanvas(self.surface_canvas)
    love.graphics.clear(0, 0, 0, 0)  -- Clear to transparent
    
    -- Calculate visible area
    local cx = self.camera:get_x()
    local left_col = math.floor(cx / C.BLOCK_SIZE)
    local right_col = math.ceil((cx + self.width) / C.BLOCK_SIZE) + 1
    
    -- Draw solid blocks as white
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(-cx, 0)
    
    -- Render all layers to surface map (not just player layer)
    -- This ensures all layers are properly lit
    for z = C.LAYER_MIN, C.LAYER_MAX do
        local layer = self.world.layers[z]
        if layer then
            for col = left_col, right_col do
                local column = layer.tiles[col]
                if column then
                    for row = 1, C.WORLD_HEIGHT do
                        local proto = column[row]
                        if proto ~= nil then
                            -- Draw solid blocks as white (occludes light)
                            love.graphics.setColor(1, 1, 1, 1)
                            local px = (col - 1) * C.BLOCK_SIZE
                            local py = (row - 1) * C.BLOCK_SIZE
                            love.graphics.rectangle("fill", px, py, C.BLOCK_SIZE, C.BLOCK_SIZE)
                        end
                    end
                end
            end
        end
    end
    
    love.graphics.pop()
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
end


function Game:draw()
    -- First, render the surface map for occlusion
    self:render_surface_map()
    
    -- Apply combined lighting shader
    if self.combined_shader and self.surface_canvas then
        love.graphics.setShader(self.combined_shader)

        -- Calculate player screen position
        local cx = self.camera:get_x()
        local player_screen_x = (self:player().px + self:player().width / 2) * C.BLOCK_SIZE - cx
        local player_screen_y = (self:player().py + self:player().height / 2) * C.BLOCK_SIZE

        -- Get sun parameters based on time of day
        local sun_intensity, sun_angle = self:get_sun_params()

        -- Set shader uniforms for player light
        self.combined_shader:send("player_pos", {player_screen_x, player_screen_y})
        self.combined_shader:send("player_radius", 300.0)
        
        -- Set shader uniforms for sun light
        self.combined_shader:send("sun_intensity", sun_intensity)
        self.combined_shader:send("sun_angle", sun_angle)
        
        -- Set surface map for occlusion calculations
        self.combined_shader:send("surface_map", self.surface_canvas)
    end

    -- world
    self.world:draw()
    -- player
    self:player():draw()

    -- Reset shader before drawing HUD
    if self.combined_shader then
        love.graphics.setShader()
    end

    -- hud
    self:player():drawInventory() -- bottom-center
    self:drawTimeHUD() -- top-right
    self:player():drawGhost() -- at mouse
    -- debug
    if self.debug then
        local cx = self.camera:get_x()
        local col = math.floor((self.mx + cx) / C.BLOCK_SIZE) + 1
        local by = math.max(1, math.min(C.WORLD_HEIGHT, math.floor(self.my / C.BLOCK_SIZE) + 1))
        local lz = self:player().z
        local block_type = self.world:get_block_type(lz, col, by)
        local block_name = (type(block_type) == "table" and block_type.name) or tostring(block_type)
        local sun_intensity, sun_angle = self:get_sun_params()
        local debug_lines = {}
        debug_lines[#debug_lines+1] = "[DEBUG]"
        debug_lines[#debug_lines+1] = string.format("Layer (player): %d", lz)
        debug_lines[#debug_lines+1] = string.format("Mouse: %.0f,%.0f %d,%d", self.mx, self.my, col, by)
        debug_lines[#debug_lines+1] = string.format("Block: %s", block_name)
        debug_lines[#debug_lines+1] = string.format("Sun: %.2f @ %.2f rad", sun_intensity, sun_angle)
        local padding = 6
        local line_h = 14
        local box_w = 420
        local box_h = #debug_lines * line_h + padding * 2
        love.graphics.setColor(T.bg[1], T.bg[2], T.bg[3], (T.bg[4] or 1) * 0.5)
        love.graphics.rectangle("fill", 6, 6, box_w, box_h)
        love.graphics.setColor(T.fg[1], T.fg[2], T.fg[3], (T.fg[4] or 1) * 1)
        for i, ln in ipairs(debug_lines) do
            love.graphics.print(ln, 10, 6 + padding + (i-1) * line_h)
        end
        love.graphics.setColor(T.fg[1], T.fg[2], T.fg[3], (T.fg[4] or 1) * 1)
    end
end

return Game
