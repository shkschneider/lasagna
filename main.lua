-- Main entry point for Lasagna
-- Wiring layer: connects systems and handles LÖVE callbacks

-- Global
G = require("game")

local WorldSystem = require("systems.world")
local PlayerSystem = require("systems.player")
local CameraSystem = require("systems.camera")
local MiningSystem = require("systems.mining")
local DropSystem = require("systems.drop")
local RenderSystem = require("systems.render")
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
    G.load(G, seed, debug)

    -- Register systems with G for coordination
    G.register_system(G, "world", WorldSystem)
    G.register_system(G, "player", PlayerSystem)
    G.register_system(G, "camera", CameraSystem)
    G.register_system(G, "mining", MiningSystem)
    G.register_system(G, "drop", DropSystem)
    G.register_system(G, "render", RenderSystem)

    -- Initialize other systems
    WorldSystem.load(WorldSystem, seed)

    local spawn_x, spawn_y, spawn_layer = WorldSystem.find_spawn_position(WorldSystem,
        math.floor(WorldSystem.WIDTH / 2), 0)

    PlayerSystem.load(PlayerSystem, spawn_x, spawn_y, spawn_layer, WorldSystem)
    CameraSystem.load(CameraSystem, spawn_x, spawn_y)
    DropSystem.load(DropSystem, WorldSystem, PlayerSystem)
    MiningSystem.load(MiningSystem, WorldSystem, PlayerSystem, DropSystem)
    RenderSystem.load(RenderSystem)

    log.info("Lasagna loaded with system architecture")
end

function love.update(dt)
    if G.is_paused(G) then
        return
    end

    -- Update game system first (handles time scale)
    G.update(G, dt)
    local scaled_dt = G.get_scaled_dt(G)

    -- Update player system
    PlayerSystem.update(PlayerSystem, scaled_dt)

    -- Update camera to follow player
    local player_x, player_y, player_layer = PlayerSystem.get_position(PlayerSystem)
    CameraSystem.update(CameraSystem, scaled_dt, player_x, player_y)

    -- Update drop system
    DropSystem.update(DropSystem, scaled_dt)
end

function love.draw()
    RenderSystem.draw(RenderSystem, WorldSystem, PlayerSystem, CameraSystem)

    -- Draw drops
    local camera_x, camera_y = CameraSystem.get_offset(CameraSystem)
    DropSystem.draw(DropSystem, camera_x, camera_y)

    -- Draw game debug info
    G.draw(G)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        return
    end

    -- Handle world reload
    if key == "delete" then
        local seed = G.get_seed(G)

        -- Reset world and entities
        WorldSystem.load(WorldSystem, seed)
        DropSystem.load(DropSystem, WorldSystem, PlayerSystem)

        -- Reset player at spawn position
        local spawn_x, spawn_y, spawn_layer = WorldSystem.find_spawn_position(WorldSystem,
            math.floor(WorldSystem.WIDTH / 2), 0)
        PlayerSystem.load(PlayerSystem, spawn_x, spawn_y, spawn_layer, WorldSystem)

        -- Reset camera to player position
        CameraSystem.load(CameraSystem, spawn_x, spawn_y)

        -- Reset mining system
        MiningSystem.load(MiningSystem, WorldSystem, PlayerSystem, DropSystem)

        return
    end

    -- Pass keypressed to systems
    G.keypressed(G, key)
    PlayerSystem.keypressed(PlayerSystem, key)
end

function love.mousepressed(x, y, button)
    local camera_x, camera_y = CameraSystem.get_offset(CameraSystem)
    MiningSystem.mousepressed(MiningSystem, x, y, button, camera_x, camera_y)
end

function love.resize(width, height)
    CameraSystem.resize(CameraSystem, width, height)
    RenderSystem.resize(RenderSystem, width, height)
end

