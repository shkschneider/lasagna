







local Object = require("lib.object")
local Blocks = require("world.blocks")
local log = require("lib.log")

local EPS = 1e-6

local Player = Object {}


function Player:new()
    self.px = 50
    self.py = 1
    self.z  = 0
    self.width = 1
    self.height = 2
    self.stand_height = self.height
    self.crouch_height = 1
    self.crouching = false
    self.on_ground = false
    self.vx = 0
    self.vy = 0
    self.canvas = nil
    self.canvas_w = 0
    self.canvas_h = 0
    self.canvas_dirty = true
    local slots = 9
    self.inventory = {
        slots = slots,
        selected = 1,
        items = {},
        ui = {
            slot_size = 48,
            padding = 6,
            border_thickness = 3,
            background_alpha = 0.6,
        },
    }
    local items_source = nil
    if type(Blocks) == "table" and type(Blocks.list) == "function" then
        items_source = Blocks.list()
    else
        local names = {}
        for k, v in pairs(Blocks) do
            if type(k) == "string" and type(v) == "table" then
                table.insert(names, k)
            end
        end
        table.sort(names)
        items_source = {}
        for _, name in ipairs(names) do
            local b = Blocks[name]
            if type(b) == "table" then
                if not b.name then b.name = name end
                table.insert(items_source, b)
            end
        end
    end
    for _, b in ipairs(items_source) do
        if #self.inventory.items >= self.inventory.slots then break end
        table.insert(self.inventory.items, b)
    end
    self.intent = { left = false, right = false, jump = false, crouch = false, run = false }
    self.ghost = { mx = 0, my = 0, z = self.z }
end


function Player:ensure_canvas(block_size)
    block_size = block_size or Game.BLOCK_SIZE
    local w_px = math.max(1, math.floor(self.width * block_size))
    local h_px = math.max(1, math.floor(self.height * block_size))
    if (not self.canvas) or self.canvas_w ~= w_px or self.canvas_h ~= h_px then
        if self.canvas and self.canvas.release then
            pcall(function() self.canvas:release() end)
        end
        self.canvas = love.graphics.newCanvas(w_px, h_px)
        self.canvas:setFilter("nearest", "nearest")
        self.canvas_w = w_px
        self.canvas_h = h_px
        self.canvas_dirty = true
    end
end


function Player:render_to_canvas(block_size)
    block_size = block_size or Game.BLOCK_SIZE
    if not self.canvas then return end
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill", 0, 0, self.width * block_size, self.height * block_size)
    love.graphics.setCanvas()
    love.graphics.pop()
    self.canvas_dirty = false
end


function Player:update(dt)
    local left = love.keyboard.isDown("a") or love.keyboard.isDown("left")
    local right = love.keyboard.isDown("d") or love.keyboard.isDown("right")
    local crouch = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
    local run = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
    self.intent.left = left
    self.intent.right = right
    self.intent.crouch = crouch
    self.intent.run = run
end



function Player:draw(block_size, camera_x)
    block_size = block_size or Game.BLOCK_SIZE
    camera_x = camera_x or 0
    self:ensure_canvas(block_size)
    if self.canvas_dirty then
        self:render_to_canvas(block_size)
    end
    local sx = (self.px - 1) * block_size - camera_x
    local sy = (self.py - 1) * block_size
    love.graphics.push()
    love.graphics.setColor(1,1,1,1)
    if self.canvas then
        love.graphics.draw(self.canvas, sx, sy)
    else
        love.graphics.rectangle("fill", sx, sy, self.width * block_size, self.height * block_size)
    end
    love.graphics.pop()
end


function Player:wheelmoved(dx, dy)
    if not dy or dy == 0 then return end
    local inv = self.inventory
    if dy > 0 then
        inv.selected = inv.selected - 1
        if inv.selected < 1 then inv.selected = inv.slots end
    else
        inv.selected = inv.selected + 1
        if inv.selected > inv.slots then inv.selected = 1 end
    end
end


function Player:drawInventory(screen_w, screen_h)
    local inv = self.inventory
    local ui = inv.ui
    local total_slots = inv.slots
    local slot_w, slot_h = ui.slot_size, ui.slot_size
    local padding = ui.padding
    local total_width = total_slots * slot_w + (total_slots - 1) * padding
    local x0 = (screen_w - total_width) / 2
    local y0 = screen_h - slot_h - 20
    local bg_margin = 8
    love.graphics.setColor(0,0,0,ui.background_alpha)
    love.graphics.rectangle("fill", x0 - bg_margin, y0 - bg_margin, total_width + bg_margin*2, slot_h + bg_margin*2, 6, 6)
    for i = 1, total_slots do
        local sx = x0 + (i-1)*(slot_w + padding)
        local sy = y0
        love.graphics.setColor(0.12,0.12,0.12,1)
        love.graphics.rectangle("fill", sx, sy, slot_w, slot_h, 4, 4)
        local inner_pad = 8
        local cube_x, cube_y = sx + inner_pad, sy + inner_pad
        local cube_w, cube_h = slot_w - inner_pad*2, slot_h - inner_pad*2
        local item = inv.items[i]
        if item and item.color then
            local r,g,b,a = unpack(item.color)
            if r and r > 1 then r,g,b,a = r/255, (g or 0)/255, (b or 0)/255, (a or 255)/255 end
            love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
            love.graphics.rectangle("fill", cube_x, cube_y, cube_w, cube_h, 3, 3)
            love.graphics.setColor(0,0,0,0.6)
            love.graphics.rectangle("line", cube_x + 0.5, cube_y + 0.5, cube_w - 1, cube_h - 1, 2, 2)
        else
            love.graphics.setColor(0.75,0.75,0.75,1)
            love.graphics.rectangle("fill", cube_x, cube_y, cube_w, cube_h, 3, 3)
        end
        love.graphics.setColor(0,0,0,0.6)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", sx + 0.5, sy + 0.5, slot_w - 1, slot_h - 1, 4, 4)
        if i == inv.selected then
            love.graphics.setColor(1, 0.84, 0, 1)
            love.graphics.setLineWidth(ui.border_thickness)
            love.graphics.rectangle("line", sx + 1, sy + 1, slot_w - 2, slot_h - 2, 4, 4)
            love.graphics.setLineWidth(1)
        end
    end
    love.graphics.setColor(1,1,1,1)
end

function Player:drawGhost(world, camera_x, block_size)
    camera_x = camera_x or 0
    block_size = block_size or Game.BLOCK_SIZE
    local inv = self.inventory
    local selected = inv.selected or 1
    local item = inv.items and inv.items[selected]
    if not item or not item.color then return end
    local screen_w, screen_h = love.graphics.getWidth(), love.graphics.getHeight()
    local ui = inv.ui
    local total_slots = inv.slots
    local slot_w = ui.slot_size
    local slot_h = ui.slot_size
    local padding = ui.padding
    local total_width = total_slots * slot_w + (total_slots - 1) * padding
    local x0 = (screen_w - total_width) / 2
    local y0 = screen_h - slot_h - 20
    local bg_margin = 8
    local inv_top = y0 - bg_margin
    local mx, my = love.mouse.getPosition()
    if my >= inv_top then return end
    local world_px = mx + camera_x
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(my / block_size) + 1
    col = math.max(1, math.min(Game.WORLD_WIDTH, col))
    row = math.max(1, math.min(Game.WORLD_HEIGHT, row))
    local px = (col - 1) * block_size - camera_x
    local py = (row - 1) * block_size
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", px + 0.5, py + 0.5, block_size - 1, block_size - 1)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1,1,1,1)
end

function Player:placeAtMouse(world, camera_x, block_size, mx, my, z_override)
    if not world then return false, "no world" end
    camera_x = camera_x or 0
    block_size = block_size or Game.BLOCK_SIZE
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then mouse_x, mouse_y = love.mouse.getPosition() end
    local inv = self.inventory
    local selected = inv.selected or 1
    local item = inv.items and inv.items[selected]
    if not item then return false, "no item selected" end
    local world_px = mouse_x + camera_x
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(mouse_y / block_size) + 1
    col = math.max(1, math.min(Game.WORLD_WIDTH, col))
    row = math.max(1, math.min(Game.WORLD_HEIGHT, row))
    local z = z_override or self.z
    local target = world:get_block_type(z, col, row)
    if target ~= "air" then return false, "target not empty", z end
    local touches_existing = false
    for dx = -1, 1 do
        for dy = -1, 1 do
            if not (dx == 0 and dy == 0) then
                local nx, ny = col + dx, row + dy
                if nx >= 1 and nx <= Game.WORLD_WIDTH and ny >= 1 and ny <= Game.WORLD_HEIGHT then
                    local neigh = world:get_block_type(z, nx, ny)
                    if neigh and neigh ~= "air" and neigh ~= "out" then
                        touches_existing = true
                        break
                    end
                end
            end
        end
        if touches_existing then break end
    end
    if not touches_existing then
        return false, "must touch an existing block on the same layer", z
    end
    local ok, action = world:set_block(z, col, row, item)
    return ok, action, z
end

function Player:removeAtMouse(world, camera_x, block_size, mx, my, z_override)
    if not world then return false, "no world" end
    camera_x = camera_x or 0
    block_size = block_size or Game.BLOCK_SIZE
    local mouse_x, mouse_y = mx, my
    if not mouse_x or not mouse_y then mouse_x, mouse_y = love.mouse.getPosition() end
    local world_px = mouse_x + camera_x
    local col = math.floor(world_px / block_size) + 1
    local row = math.floor(mouse_y / block_size) + 1
    col = math.max(1, math.min(Game.WORLD_WIDTH, col))
    row = math.max(1, math.min(Game.WORLD_HEIGHT, row))
    if z_override then
        local z = z_override
        local ok, msg = world:set_block(z, col, row, nil)
        if ok then return true, msg, z end
        local ok2, msg2 = world:set_block(z, col, row, "__empty")
        if ok2 then return true, msg2, z end
        return false, "nothing to remove", nil
    end
    local layer_order = {1, 0, -1}
    for _, z in ipairs(layer_order) do
        local t = world:get_block_type(z, col, row)
        if t and t ~= "air" and t ~= "out" then
            local ok, msg = world:set_block(z, col, row, nil)
            if ok then
                log.info(string.format("Removed block at z=%d, col=%d, row=%d (overlay)", z, col, row))
                return true, msg, z
            end
            local ok2, msg2 = world:set_block(z, col, row, "__empty")
            if ok2 then
                log.info(string.format("Marked procedural block removed at z=%d, col=%d, row=%d", z, col, row))
                return true, msg2, z
            end
            return false, "failed to remove block at target layer", z
        end
    end
    return false, "nothing to remove", nil
end

return Player