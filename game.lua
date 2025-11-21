-- Main game controller

local world = require("world")
local player = require("player")
local camera = require("camera")
local render = require("render")
local entities = require("entities")
local blocks = require("blocks")
local inventory = require("inventory")

local game = {}

function game.new(seed, debug)
    local g = {
        world = world.new(seed),
        player = nil,
        camera = nil,
        renderer = render.new(),
        entities = entities.new(),
        debug = debug or false,
        paused = false,
    }
    
    -- Initialize player at spawn point (finds ground automatically)
    local spawn_x, spawn_y, spawn_layer = world.find_spawn_position(g.world, 
        math.floor(world.WIDTH / 2), 0)
    g.player = player.new(spawn_x, spawn_y, spawn_layer)
    
    -- Give player some starting items for testing
    inventory.add(g.player.inventory, blocks.DIRT, 64)
    inventory.add(g.player.inventory, blocks.STONE, 32)
    inventory.add(g.player.inventory, blocks.WOOD, 16)
    
    -- Initialize camera
    g.camera = camera.new(spawn_x, spawn_y)
    
    return g
end

function game.load(g)
    -- Create render canvases
    render.create_canvases(g.renderer)
end

function game.update(g, dt)
    if g.paused then
        return
    end
    
    -- Update player
    player.update(g.player, dt, g.world)
    
    -- Update camera to follow player
    camera.follow(g.camera, g.player.x, g.player.y, dt)
    
    -- Update entities
    entities.update(g.entities, dt, g.world, g.player)
end

function game.draw(g)
    local camera_x, camera_y = camera.get_offset(g.camera, 
        g.renderer.screen_width, g.renderer.screen_height)
    
    -- Draw world to layer canvases
    render.draw_world(g.renderer, g.world, g.player.layer, camera_x, camera_y)
    
    -- Composite layers to screen
    render.composite_layers(g.renderer, g.player.layer)
    
    -- Draw entities
    entities.draw(g.entities, camera_x, camera_y)
    
    -- Draw player
    player.draw(g.player, camera_x, camera_y)
    
    -- Draw UI
    render.draw_ui(g.renderer, g.player, g.world, camera_x, camera_y)
    
    -- Debug info
    if g.debug then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 100)
        love.graphics.print("Seed: " .. g.world.seed, 10, 120)
    end
end

function game.keypressed(g, key)
    -- Layer switching (only if player can fit in target layer)
    if key == "q" then
        local target_layer = math.max(-1, g.player.layer - 1)
        if game.can_switch_layer(g, target_layer) then
            g.player.layer = target_layer
        end
    elseif key == "e" then
        local target_layer = math.min(1, g.player.layer + 1)
        if game.can_switch_layer(g, target_layer) then
            g.player.layer = target_layer
        end
    end
    
    -- Hotbar selection (1-9 keys)
    local num = tonumber(key)
    if num and num >= 1 and num <= 9 then
        inventory.select_slot(g.player.inventory, num)
    end
    
    -- Debug: add test item
    if key == "t" and g.debug then
        inventory.add(g.player.inventory, blocks.COPPER_ORE, 5)
    end
    
    -- Development: adjust omnitool tier
    if key == "=" or key == "+" then
        g.player.omnitool_tier = math.min(10, g.player.omnitool_tier + 1)
    elseif key == "-" or key == "_" then
        g.player.omnitool_tier = math.max(0, g.player.omnitool_tier - 1)
    end
    
    -- Reload world (complete reset)
    if key == "delete" then
        -- Save the seed before resetting
        local seed = g.world.seed
        
        -- Reset world and entities
        g.world = world.new(seed)
        g.entities = entities.new()
        
        -- Reset player at spawn position
        local spawn_x, spawn_y, spawn_layer = world.find_spawn_position(g.world, 
            math.floor(world.WIDTH / 2), 0)
        g.player = player.new(spawn_x, spawn_y, spawn_layer)
        
        -- Give player starting items again
        inventory.add(g.player.inventory, blocks.DIRT, 64)
        inventory.add(g.player.inventory, blocks.STONE, 32)
        inventory.add(g.player.inventory, blocks.WOOD, 16)
        
        -- Reset camera to player position
        g.camera.x = spawn_x
        g.camera.y = spawn_y
    end
end

-- Check if player can switch to target layer (no collision)
function game.can_switch_layer(g, target_layer)
    if target_layer < -1 or target_layer > 1 then
        return false
    end
    
    -- Check if player would collide with blocks in target layer
    return not player.check_collision(g.player, g.world, g.player.x, g.player.y, target_layer)
end

function game.mousepressed(g, x, y, button)
    local camera_x, camera_y = camera.get_offset(g.camera,
        g.renderer.screen_width, g.renderer.screen_height)
    
    local world_x = x + camera_x
    local world_y = y + camera_y
    
    local col, row = world.world_to_block(world_x, world_y)
    
    if button == 1 then
        -- Left click: mine block
        game.mine_block(g, col, row)
    elseif button == 2 then
        -- Right click: place block
        game.place_block(g, col, row)
    end
end

function game.mine_block(g, col, row)
    local block_id = world.get_block(g.world, g.player.layer, col, row)
    local proto = blocks.get_proto(block_id)
    
    if not proto or not proto.solid then
        return
    end
    
    -- Check tier requirement
    if proto.tier > g.player.omnitool_tier then
        return -- Can't mine this yet
    end
    
    -- Remove block
    world.set_block(g.world, g.player.layer, col, row, blocks.AIR)
    
    -- Spawn drop
    if proto.drops then
        local drop_id, drop_count = proto.drops()
        if drop_id then
            local wx, wy = world.block_to_world(col, row)
            entities.create_drop(g.entities, wx + world.BLOCK_SIZE / 2, 
                wy + world.BLOCK_SIZE / 2, g.player.layer, drop_id, drop_count)
        end
    end
end

function game.place_block(g, col, row)
    local block_id = inventory.get_selected_block_id(g.player.inventory)
    
    if not block_id then
        return
    end
    
    -- Check if spot is empty
    local current_block = world.get_block(g.world, g.player.layer, col, row)
    if current_block ~= blocks.AIR then
        return
    end
    
    -- Place block
    if world.set_block(g.world, g.player.layer, col, row, block_id) then
        -- Remove from inventory
        inventory.remove_from_selected(g.player.inventory, 1)
    end
end

function game.resize(g, width, height)
    g.renderer.screen_width = width
    g.renderer.screen_height = height
    render.create_canvases(g.renderer)
end

return game
