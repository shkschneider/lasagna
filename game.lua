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
    local self = {
        world = world.new(seed),
        player = nil,
        camera = nil,
        renderer = render.new(),
        entities = entities.new(),
        debug = debug or false,
        paused = false,
    }

    -- Initialize player at spawn point (finds ground automatically)
    local spawn_x, spawn_y, spawn_layer = world.find_spawn_position(self.world,
        math.floor(world.WIDTH / 2), 0)
    self.player = player.new(spawn_x, spawn_y, spawn_layer)

    -- Give player some starting items for testing
    inventory.add(self.player.inventory, blocks.DIRT, 64)
    inventory.add(self.player.inventory, blocks.STONE, 32)
    inventory.add(self.player.inventory, blocks.WOOD, 16)

    -- Initialize camera
    self.camera = camera.new(spawn_x, spawn_y)

    return self
end

function game.load(self)
    -- Create render canvases
    render.create_canvases(self.renderer)
end

function game.update(self, dt)
    if self.paused then
        return
    end

    -- Update player
    player.update(self.player, dt, self.world)

    -- Update camera to follow player
    camera.follow(self.camera, self.player.x, self.player.y, dt)

    -- Update entities
    entities.update(self.entities, dt, self.world, self.player)
end

function game.draw(self)
    local camera_x, camera_y = camera.get_offset(self.camera,
        self.renderer.screen_width, self.renderer.screen_height)

    -- Draw world to layer canvases
    render.draw_world(self.renderer, self.world, self.player.layer, camera_x, camera_y)

    -- Composite layers to screen
    render.composite_layers(self.renderer, self.player.layer)

    -- Draw entities
    entities.draw(self.entities, camera_x, camera_y)

    -- Draw player
    player.draw(self.player, camera_x, camera_y)

    -- Draw UI
    render.draw_ui(self.renderer, self.player, self.world, camera_x, camera_y)

    -- Debug info
    if self.debug then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 100)
        love.graphics.print("Seed: " .. self.world.seed, 10, 120)
    end
end

function game.keypressed(self, key)
    -- Layer switching (only if player can fit in target layer)
    if key == "q" then
        local target_layer = math.max(-1, self.player.layer - 1)
        if game.can_switch_layer(self, target_layer) then
            self.player.layer = target_layer
        end
    elseif key == "e" then
        local target_layer = math.min(1, self.player.layer + 1)
        if game.can_switch_layer(self, target_layer) then
            self.player.layer = target_layer
        end
    end

    -- Hotbar selection (1-9 keys)
    local num = tonumber(key)
    if num and num >= 1 and num <= 9 then
        inventory.select_slot(self.player.inventory, num)
    end

    -- Debug: add test item
    if key == "t" and self.debug then
        inventory.add(self.player.inventory, blocks.COPPER_ORE, 5)
    end

    -- Development: adjust omnitool tier
    if key == "=" or key == "+" then
        self.player.omnitool_tier = math.min(10, self.player.omnitool_tier + 1)
    elseif key == "-" or key == "_" then
        self.player.omnitool_tier = math.max(0, self.player.omnitool_tier - 1)
    end

    -- Reload world (complete reset)
    if key == "delete" then
        -- Save the seed before resetting
        local seed = self.world.seed

        -- Reset world and entities
        self.world = world.new(seed)
        self.entities = entities.new()

        -- Reset player at spawn position
        local spawn_x, spawn_y, spawn_layer = world.find_spawn_position(self.world,
            math.floor(world.WIDTH / 2), 0)
        self.player = player.new(spawn_x, spawn_y, spawn_layer)

        -- Give player starting items again
        inventory.add(self.player.inventory, blocks.DIRT, 64)
        inventory.add(self.player.inventory, blocks.STONE, 32)
        inventory.add(self.player.inventory, blocks.WOOD, 16)

        -- Reset camera to player position
        self.camera.x = spawn_x
        self.camera.y = spawn_y
    end
end

-- Check if player can switch to target layer (no collision)
function game.can_switch_layer(self, target_layer)
    if target_layer < -1 or target_layer > 1 then
        return false
    end

    -- Check if player would collide with blocks in target layer
    return not player.check_collision(self.player, self.world, self.player.x, self.player.y, target_layer)
end

function game.mousepressed(self, x, y, button)
    local camera_x, camera_y = camera.get_offset(self.camera,
        self.renderer.screen_width, self.renderer.screen_height)

    local world_x = x + camera_x
    local world_y = y + camera_y

    local col, row = world.world_to_block(world_x, world_y)

    if button == 1 then
        -- Left click: mine block
        game.mine_block(self, col, row)
    elseif button == 2 then
        -- Right click: place block
        game.place_block(self, col, row)
    end
end

function game.mine_block(self, col, row)
    local block_id = world.get_block(self.world, self.player.layer, col, row)
    local proto = blocks.get_proto(block_id)

    if not proto or not proto.solid then
        return
    end

    -- Check tier requirement
    if proto.tier > self.player.omnitool_tier then
        return -- Can't mine this yet
    end

    -- Remove block
    world.set_block(self.world, self.player.layer, col, row, blocks.AIR)

    -- Spawn drop
    if proto.drops then
        local drop_id, drop_count = proto.drops()
        if drop_id then
            local wx, wy = world.block_to_world(col, row)
            entities.create_drop(self.entities, wx + world.BLOCK_SIZE / 2,
                wy + world.BLOCK_SIZE / 2, self.player.layer, drop_id, drop_count)
        end
    end
end

function game.place_block(self, col, row)
    local block_id = inventory.get_selected_block_id(self.player.inventory)

    if not block_id then
        return
    end

    -- Check if spot is empty
    local current_block = world.get_block(self.world, self.player.layer, col, row)
    if current_block ~= blocks.AIR then
        return
    end

    -- Place block
    if world.set_block(self.world, self.player.layer, col, row, block_id) then
        -- Remove from inventory
        inventory.remove_from_selected(self.player.inventory, 1)
    end
end

function game.resize(self, width, height)
    self.renderer.screen_width = width
    self.renderer.screen_height = height
    render.create_canvases(self.renderer)
end

return game
