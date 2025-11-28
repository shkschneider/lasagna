local Love = require "core.love"
local Object = require "core.object"

local Jetpack = Object {
    id = "jetpack",
    priority = 61,  -- Run before weapon (62)
    thrusting = false,
    STAMINA_COST = 2,  -- per second
    THRUST_FORCE = 200,
}

function Jetpack.load(self)
    self.thrusting = false
    Love.load(self)
end

function Jetpack.update(self, dt)
    -- Check if space is held and player has stamina
    local space_held = love.keyboard.isDown("space")

    -- Only allow jetpack when in the air
    local on_ground = G.player.on_ground

    if space_held and not on_ground then
        -- Check if player has enough stamina
        local stamina_cost = self.STAMINA_COST * dt
        if G.player.stamina and G.player.stamina.current >= stamina_cost then
            -- Consume stamina
            G.player.stamina.current = math.max(0, G.player.stamina.current - stamina_cost)

            -- Apply upward thrust
            G.player.velocity.y = G.player.velocity.y - self.THRUST_FORCE * dt

            self.thrusting = true
        else
            self.thrusting = false
        end
    else
        self.thrusting = false
    end

    Love.update(self, dt)
end

return Jetpack
