-- Main entry point for Lasagna

local SystemManager = require("system_manager")
local GameSystem = require("systems/game")
local WorldSystem = require("systems/world")
local PlayerSystem = require("systems/player")
local CameraSystem = require("systems/camera")
local MiningSystem = require("systems/mining")
local DropSystem = require("systems/drop")
local RenderSystem = require("systems/render")
local log = require("lib.log")

-- Global system manager
G = {}

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

    -- Initialize systems and push to manager
    SystemManager:push(GameSystem)
    SystemManager:push(WorldSystem)
    SystemManager:push(PlayerSystem)
    SystemManager:push(CameraSystem)
    SystemManager:push(MiningSystem)
    SystemManager:push(DropSystem)
    SystemManager:push(RenderSystem)
    
    -- Load systems
    GameSystem:load(seed, debug)
    WorldSystem:load(seed)
    
    -- Find spawn position
    local spawn_x, spawn_y, spawn_layer = WorldSystem:find_spawn_position(
        math.floor(WorldSystem.WIDTH / 2), 0)
    
    PlayerSystem:load(spawn_x, spawn_y, spawn_layer, WorldSystem)
    CameraSystem:load(spawn_x, spawn_y)
    MiningSystem:load(WorldSystem, PlayerSystem)
    DropSystem:load(WorldSystem, PlayerSystem)
    RenderSystem:load()
    
    -- Set drop system reference for mining
    MiningSystem:set_drop_system(DropSystem)
    
    -- Store systems globally for easy access
    G.game = GameSystem
    G.world = WorldSystem
    G.player = PlayerSystem
    G.camera = CameraSystem
    G.mining = MiningSystem
    G.drop = DropSystem
    G.render = RenderSystem

    log.info("Lasagna loaded with system architecture")
end

function love.update(dt)
    if G.game:is_paused() then
        return
    end
    
    -- Update game system first (handles time scale)
    GameSystem:update(dt)
    local scaled_dt = GameSystem:get_scaled_dt()
    
    -- Update other systems
    PlayerSystem:update(scaled_dt)
    
    local player_x, player_y, player_layer = PlayerSystem:get_position()
    CameraSystem:update(scaled_dt, player_x, player_y)
    
    DropSystem:update(scaled_dt)
end

function love.draw()
    RenderSystem:draw(WorldSystem, PlayerSystem, CameraSystem)
    
    -- Draw drops
    local camera_x, camera_y = CameraSystem:get_offset()
    DropSystem:draw(camera_x, camera_y)
    
    -- Draw game debug info
    GameSystem:draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        return
    end
    
    -- Handle world reload
    if key == "delete" then
        local seed = GameSystem:get_seed()
        
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
        MiningSystem:load(WorldSystem, PlayerSystem)
        MiningSystem:set_drop_system(DropSystem)
        
        return
    end
    
    SystemManager:keypressed(key)
end

function love.mousepressed(x, y, button)
    local camera_x, camera_y = CameraSystem:get_offset()
    MiningSystem:mousepressed(x, y, button, camera_x, camera_y)
end

function love.resize(width, height)
    SystemManager:resize(width, height)
end
