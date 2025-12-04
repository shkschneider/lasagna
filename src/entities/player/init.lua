local Love = require "core.love"
local Object = require "core.object"
local Control = require "src.entities.control"
local Physics = require "src.world.physics"
local Inventory = require "src.entities.inventory"
local Stack = require "src.entities.stack"
local Weapon = require "src.entities.weapon"
local Jetpack = require "src.entities.jetpack"
local Vector = require "src.game.vector"
local Omnitool = require "src.entities.omnitool"
local Stance = require "src.entities.stance"
local Health = require "src.entities.health"
local Armor = require "src.entities.armor"
local Stamina = require "src.entities.stamina"
local Registry = require "src.registries"
local ITEMS = Registry.items()

Player = Object {
    id = "player",
    priority = 20,
    -- Constants
    SAFE_FALL_BLOCKS = 4,  -- 2x player height
    FALL_DAMAGE_PER_BLOCK = 5,
    STAMINA_REGEN_RATE = 1,  -- per second
    HOTBAR_SIZE = 9,
    BACKPACK_SIZE = 27,  -- 3 rows of 9
}

local here = (...):gsub("%.init$", "") .. "."
require(here .. "_update")
require(here .. "_inventory")

function Player.load(self)
    self.width = BLOCK_SIZE
    self.height = BLOCK_SIZE * 2
    self.color = { 1, 1, 1, 1 }

    -- Sytems
    self.hotbar = Inventory.new(self.HOTBAR_SIZE)
    self.backpack = Inventory.new(self.BACKPACK_SIZE)
    self.control = Control.new()
    self.weapon = Weapon
    self.jetpack = G.debug and Jetpack or nil

    -- s
    local x, y, z = G.world:find_spawn_position(LAYER_DEFAULT)
    self.position = Vector.new(x, y, z)
    self.velocity = Vector.new(0, 0)
    self.velocity.enabled = false
    self.gravity = Physics.DEFAULT_GRAVITY
    self.friction = Physics.DEFAULT_FRICTION
    self.omnitool = Omnitool.new()
    self.stance = Stance.new(Stance.STANDING)
    self.stance.crouched = false
    self.health = Health.new(100, 100)
    self.armor = Armor.new(G.debug and 50 or 0, 100)
    self.stamina = Stamina.new(100, 100, Player.STAMINA_REGEN_RATE)

    -- Fall damage tracking
    self.fall_start_y = nil
    self.inventory_open = false  -- Whether the full inventory (backpack) is displayed

    -- Cached ground state (updated after physics resolution each frame)
    -- Initialize based on actual spawn position
    self.on_ground = Physics.is_on_ground(G.world, self.position, self.width, self.height)
    if not self.on_ground then
        Log.warning("Player not on ground!")
    end

    -- Items
    self.hotbar:set_slot(1, Stack.new(ITEMS.OMNITOOL, 1, "item"))
    if G.debug then
        Log.debug(G.world:world_to_block(self.position.x, self.position.y))
        self.hotbar:set_slot(2, Stack.new(ITEMS.GUN, 1, "item"))
        self.hotbar:set_slot(3, Stack.new(ITEMS.ROCKET_LAUNCHER, 1, "item"))
    end

    Love.load(self)
end

function Player.update(self, dt)
    -- Manually update health, armor, and stamina components
    self.health:update(dt)
    self.armor:update(dt)
    self.stamina:update(dt)

    -- Call other component updates via Object recursion
    Love.update(self, dt)

    if self:is_dead() then return end

    self:_update(dt)
end

function Player.draw(self)
    local pos = self.position

    local camera_x, camera_y = G.camera:get_offset()

    -- Draw player using direct properties
    if self:is_dead() then
        love.graphics.setColor(1, 0, 0, 1) -- red
    else
        love.graphics.setColor(self.color)
    end
    love.graphics.rectangle("fill",
        pos.x - camera_x - self.width / 2,
        pos.y - camera_y - self.height / 2,
        self.width,
        self.height)

    -- Draw red border if recently damaged
    if self.health:is_recently_damaged() then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line",
            pos.x - camera_x - self.width / 2,
            pos.y - camera_y - self.height / 2,
            self.width,
            self.height)
    end

    if self.control.jetpack_thrusting then
        local jx, jy = pos.x - camera_x,
            pos.y - camera_y + self.height / 2
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.line(jx, jy, jx, jy + BLOCK_SIZE)
    end

    -- Draw health, armor, and stamina bars (UI elements, not camera-relative)
    self.health:draw()  -- First bar
    self.armor:draw()   -- Second bar
    self.stamina:draw() -- Third bar

    Love.draw(self)
end

function Player.keypressed(self, key)
    if key == "tab" then
        self.inventory_open = not self.inventory_open
    elseif not self.inventory_open then
        Love.keypressed(self, key)
    end
end

function Player.can_switch_layer(self, target_layer)
    return G.world:can_switch_layer(target_layer)
        and not Physics.check_collision(G.world, self.position.x + 1, self.position.y + 1, target_layer, self.width - 2, self.height - 2)
end

function Player.upgrade(self, upOrDown)
    assert(type(upOrDown) == "number")
    if upOrDown > 0 then
        self.omnitool.tier = math.min(self.omnitool.tier + 1, self.omnitool.max)
        Log.info("Player", "upgrade", self.omnitool.tier)
    elseif upOrDown < 0 then
        self.omnitool.tier = math.max(self.omnitool.min, self.omnitool.tier - 1)
        Log.info("Player", "downgrade", self.omnitool.tier)
    else
        assert(false)
    end
end

function Player.get_position(self)
    return self.position.x, self.position.y, self.position.z
end

function Player.get_omnitool_tier(self)
    return self.omnitool.tier
end

function Player.is_on_ground(self)
    return Physics.is_on_ground(G.world, self.position, self.width, self.height)
end

function Player.can_stand_up(self)
    local pos = self.position
    local target_y = pos.y - BLOCK_SIZE / 2  -- Position after standing
    local top_y = target_y - BLOCK_SIZE  -- Top of standing height
    local left_col = math.floor((pos.x - self.width / 2) / BLOCK_SIZE)
    local right_col = math.floor((pos.x + self.width / 2 - math.eps) / BLOCK_SIZE)
    local top_row = math.floor(top_y / BLOCK_SIZE)

    for c = left_col, right_col do
        local block_def = G.world:get_block_def(pos.z, c, top_row)
        if block_def and block_def.solid then
            return false
        end
    end

    return true
end

function Player.hit(self, damage)
    if not self.health then return end
    damage = self.stance.crouched and (damage / 2) or damage
    -- Armor halfs the damage
    if self.armor and self.armor.current > 0 then
        local dmg = math.min(damage, self.armor.current * 2)
        self.armor:hit(dmg / 2)
        damage = damage - dmg
    end
    -- Apply remaining damage to health
    if damage > 0 then
        self.health:hit(damage)
    end
    -- Death?
end

function Player.is_dead(self)
    return self.health and self.health.current <= 0
end

return Player
