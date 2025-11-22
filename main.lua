-- Main entry point for Lasagna
-- Wiring layer: connects systems and handles LÖVE callbacks

-- Global
G = require("game")

local WorldSystem = require("systems/world")
local PlayerSystem = require("systems/player")
local CameraSystem = require("systems/camera")
local MiningSystem = require("systems/mining")
local DropSystem = require("systems/drop")
local RenderSystem = require("systems/render")
local log = require("lib.log")

function love.load()
    -- Parse environment variables
    local debug = os.getenv("DEBUG") == "true"
    local seed = tonumber(os.getenv("SEED"))

    if debug then
        log.level = "debug"
        log.debug("Debug mode enabled")
    end

    if seed then
        log.info("Using seed:", seed)
    end

    -- Initialize and register systems with G
    G:load(seed, debug)

    -- Register systems with G for coordination
    G:register_system("world", WorldSystem)
    G:register_system("player", PlayerSystem)
    G:register_system("camera", CameraSystem)
    G:register_system("mining", MiningSystem)
    G:register_system("drop", DropSystem)
    G:register_system("render", RenderSystem)

    -- Initialize other systems
    WorldSystem:load(seed)

    local spawn_x, spawn_y, spawn_layer = WorldSystem:find_spawn_position(
        math.floor(WorldSystem.WIDTH / 2), 0)

    PlayerSystem:load(spawn_x, spawn_y, spawn_layer, WorldSystem)
    CameraSystem:load(spawn_x, spawn_y)
    DropSystem:load(WorldSystem, PlayerSystem)
    MiningSystem:load(WorldSystem, PlayerSystem, DropSystem)
    RenderSystem:load()

    log.info("Lasagna loaded with system architecture")
end

function love.update(dt)
    if G:is_paused() then
        return
    end

    -- Update game system first (handles time scale)
    G:update(dt)
    local scaled_dt = G:get_scaled_dt()

    -- Update player system
    PlayerSystem:update(scaled_dt)

    -- Update camera to follow player
    local player_x, player_y, player_layer = PlayerSystem:get_position()
    CameraSystem:update(scaled_dt, player_x, player_y)

    -- Update drop system
    DropSystem:update(scaled_dt)
end

function love.draw()
    RenderSystem:draw(WorldSystem, PlayerSystem, CameraSystem)

    -- Draw drops
    local camera_x, camera_y = CameraSystem:get_offset()
    DropSystem:draw(camera_x, camera_y)

    -- Draw game debug info
    G:draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        return
    end

    -- Handle world reload
    if key == "delete" then
        local seed = G:get_seed()

        -- Reset world and entities
        WorldSystem:load(seed)
        DropSystem:load(WorldSystem, PlayerSystem)

        -- Reset player at spawn position
        local spawn_x, spawn_y, spawn_layer = WorldSystem:find_spawn_position(
            math.floor(WorldSystem.WIDTH / 2), 0)
        PlayerSystem:load(spawn_x, spawn_y, spawn_layer, WorldSystem)

        -- Reset camera to player position
        CameraSystem:load(spawn_x, spawn_y)

        -- Reset mining system
        MiningSystem:load(WorldSystem, PlayerSystem, DropSystem)

        return
    end

    -- Pass keypressed to systems
    G:keypressed(key)
    PlayerSystem:keypressed(key)
end

function love.mousepressed(x, y, button)
    local camera_x, camera_y = CameraSystem:get_offset()
    MiningSystem:mousepressed(x, y, button, camera_x, camera_y)
end

function love.resize(width, height)
    for _, system in ipairs(G.systems) do
        if type(system.resize) == "function" then
            system.resize(width, height)
        end
    end
end
