-- Weapon item definitions

local ItemRef = require "data.items.ids"
local ItemsRegistry = require "registries.items"

-- Register Gun
ItemsRegistry:register({
    id = ItemRef.GUN,
    name = "Gun",
    weapon = {
        cooldown = 0.2,  -- Short cooldown for auto-fire
        bullet_speed = 400,
        bullet_width = 2,
        bullet_height = 2,
        bullet_color = {1, 1, 0, 1},  -- Yellow
    },
})

-- Register Rocket Launcher
ItemsRegistry:register({
    id = ItemRef.ROCKET_LAUNCHER,
    name = "Rocket Launcher",
    weapon = {
        cooldown = 0.8,  -- 4x gun cooldown
        bullet_speed = 300,
        bullet_width = 4,  -- 2x gun bullet width
        bullet_height = 4,  -- 2x gun bullet height
        bullet_color = {1, 0.5, 0, 1},  -- Orange
    },
})
