-- main.lua for Love2D: Minimalist Terraria-like World with Layers and Player

-- Perlin noise implementation
local p = {}
for i = 1, 256 do
    p[i] = math.random(0, 255)
    p[i + 256] = p[i]
end

local function fade(t) return t * t * t * (t * (t * 6 - 15) + 10) end
local function lerp(t, a, b) return a + t * (b - a) end
local function grad(hash, x) return (hash % 2 == 0 and x or -x) end

local function noise(x)
    local xi = math.floor(x) % 256
    local xf = x % 1
    local u = fade(xf)
    local a = p[xi + 1]
    local b = p[xi + 2]
    return lerp(u, grad(a, xf), grad(b, xf - 1)) * 2
end

local function perlin1d(x, octaves, persistence)
    local total, amp, freq, max_val = 0, 1, 1, 0
    for i = 1, octaves do
        total = total + noise(x * freq) * amp
        max_val = max_val + amp
        amp = amp * persistence
        freq = freq * 2
    end
    return total / max_val
end

-- World properties
local block_size = 16
local world_width = 500
local world_height = 100
local layers = {}
local current_layer = 0  -- Default layer
local camera_x = 0
local screen_width, screen_height
local player = {x = 50, y = 0, width = 1, height = 2, vx = 0, vy = 0, on_ground = false, z = 0}

-- Physics constants
local gravity = 20  -- Blocks per second squared
local jump_velocity = -8.94  -- For ~2 block jump height
local move_speed = 5  -- Blocks per second

function love.load()
    love.window.setMode(1280, 720)
    screen_width = love.graphics.getWidth()
    screen_height = love.graphics.getHeight()

    -- Generate layers (-1: back, 0: default, 1: front)
    for z = -1, 1 do
        layers[z] = {tiles = {}, heights = {}}
        local base_height = world_height * 0.3
        local amplitude = 10
        local frequency = 1 / 50
        local octaves = 4
        local persistence = 0.5
        if z == -1 then
            frequency = 1 / 40
            amplitude = 15
        elseif z == 1 then
            frequency = 1 / 60
            amplitude = 12
        end

        for x = 1, world_width do
            local noise_val = perlin1d(x * frequency + (z * 100), octaves, persistence)
            local height = math.floor(base_height + amplitude * noise_val)
            height = math.max(1, math.min(45, height))
            layers[z].heights[x] = height

            -- Grass tile
            table.insert(layers[z].tiles, {x = x, y = height, type = "grass"})

            -- Dirt tiles below
            for y = height + 1, world_height do
                table.insert(layers[z].tiles, {x = x, y = y, type = "dirt"})
            end
        end
    end

    -- Set player starting position (on default layer grass)
    player.y = layers[0].heights[math.floor(player.x)] - player.height
end

function love.keypressed(key)
    if key == "1" then
        current_layer = -1
        player.z = -1
        player.y = layers[-1].heights[math.floor(player.x)] - player.height
        player.vy = 0
        player.on_ground = true
    elseif key == "2" then
        current_layer = 0
        player.z = 0
        player.y = layers[0].heights[math.floor(player.x)] - player.height
        player.vy = 0
        player.on_ground = true
    elseif key == "3" then
        current_layer = 1
        player.z = 1
        player.y = layers[1].heights[math.floor(player.x)] - player.height
        player.vy = 0
        player.on_ground = true
    elseif key == "escape" then
        love.event.quit()
    elseif key == "space" and player.on_ground then
        player.vy = jump_velocity
        player.on_ground = false
    end
end

function love.update(dt)
    -- Horizontal movement
    local new_x = player.x
    if love.keyboard.isDown("d") then
        new_x = player.x + move_speed * dt
    elseif love.keyboard.isDown("a") then
        new_x = player.x - move_speed * dt
    end

    -- Check ground height for movement
    local current_ground_y = layers[player.z].heights[math.floor(player.x + player.width / 2)] or 100
    local target_ground_y = layers[player.z].heights[math.floor(new_x + player.width / 2)] or 100
    if target_ground_y <= current_ground_y or player.vy < 0 then
        player.x = new_x
    end

    -- Clamp player x
    player.x = math.max(1, math.min(world_width - player.width, player.x))

    -- Apply gravity
    player.vy = player.vy + gravity * dt

    -- Update y position
    player.y = player.y + player.vy * dt

    -- Ground collision
    local ground_y = layers[player.z].heights[math.floor(player.x + player.width / 2)] or 100
    if player.y + player.height > ground_y then
        player.y = ground_y - player.height
        player.vy = 0
        player.on_ground = true
    else
        player.on_ground = false
    end

    -- Clamp y
    player.y = math.min(player.y, world_height - player.height)

    -- Center camera
    camera_x = (player.x + player.width / 2) * block_size - screen_width / 2
    camera_x = math.max(0, math.min(camera_x, world_width * block_size - screen_width))
end

function love.draw()
    love.graphics.translate(-camera_x, 0)

    -- Draw current and back layers (z <= current_layer)
    for z = -1, current_layer do
        local alpha = z == current_layer and 1 or (1 - 0.1 * (current_layer - z))
        for _, tile in ipairs(layers[z].tiles) do
            local px, py = (tile.x - 1) * block_size, (tile.y - 1) * block_size
            if px + block_size >= camera_x and px <= camera_x + screen_width and py <= screen_height then
                if tile.type == "grass" then
                    love.graphics.setColor(0.2, 0.6, 0.2, alpha)
                else
                    love.graphics.setColor(0.6, 0.3, 0.1, alpha)
                end
                love.graphics.rectangle("fill", px, py, block_size, block_size)
            end
        end
    end

    -- Draw player
    if player.z == current_layer then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", (player.x - 1) * block_size, (player.y - 1) * block_size, block_size, 2 * block_size)
    end

    love.graphics.setColor(1, 1, 1)
end