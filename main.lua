-- main.lua
-- Single-file Love2D starter: player movement, shooting, enemies, collisions, score.
-- No conf.lua required; window is configured in love.load.

local Player = {}
local Bullets = {}
local enemies = {}

local screen = { w = 800, h = 600 }
local enemySpawnTimer = 0
local enemySpawnInterval = 2 -- seconds
local score = 0
local font

-- Utility: AABB rectangle overlap
local function rectsOverlap(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

-- --------------------------
-- Player
-- --------------------------
Player.x = 0
Player.y = 0
Player.w = 28
Player.h = 28
Player.speed = 220
Player.shootCooldown = 0.18
Player.shootTimer = 0

function Player.init(x, y)
    Player.x = x - Player.w / 2
    Player.y = y - Player.h / 2
    Player.shootTimer = 0
end

function Player.update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then dx = dx + 1 end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then dy = dy + 1 end

    if dx ~= 0 and dy ~= 0 then
        dx = dx * 0.7071
        dy = dy * 0.7071
    end

    Player.x = Player.x + dx * Player.speed * dt
    Player.y = Player.y + dy * Player.speed * dt

    -- clamp to screen
    Player.x = math.max(0, math.min(screen.w - Player.w, Player.x))
    Player.y = math.max(0, math.min(screen.h - Player.h, Player.y))

    -- shoot timer
    Player.shootTimer = math.max(0, Player.shootTimer - dt)

    -- auto-shoot while holding space
    if love.keyboard.isDown("space") and Player.shootTimer == 0 then
        Player.shoot()
    end
end

function Player.shoot()
    if Player.shootTimer > 0 then return end
    local bx = Player.x + Player.w / 2 - 4
    local by = Player.y - 10
    Bullets.spawn(bx, by, 0, -400)
    Player.shootTimer = Player.shootCooldown
end

function Player.draw()
    love.graphics.setColor(0.2, 0.6, 0.9)
    love.graphics.rectangle("fill", Player.x, Player.y, Player.w, Player.h)
    love.graphics.setColor(1,1,1)
end

-- --------------------------
-- Bullets
-- --------------------------
Bullets.list = {}

function Bullets.init()
    Bullets.list = {}
end

function Bullets.spawn(x, y, vx, vy)
    local b = {
        x = x,
        y = y,
        w = 8,
        h = 10,
        vx = vx or 0,
        vy = vy or -400
    }
    table.insert(Bullets.list, b)
end

function Bullets.update(dt)
    for i = #Bullets.list, 1, -1 do
        local b = Bullets.list[i]
        b.x = b.x + (b.vx or 0) * dt
        b.y = b.y + (b.vy or 0) * dt

        if b.y < -50 or b.y > screen.h + 50 or b.x < -50 or b.x > screen.w + 50 then
            table.remove(Bullets.list, i)
        end
    end
end

function Bullets.draw()
    love.graphics.setColor(1, 0.9, 0.2)
    for _, b in ipairs(Bullets.list) do
        love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
    end
    love.graphics.setColor(1,1,1)
end

-- --------------------------
-- Enemies
-- --------------------------
local function spawnEnemy()
    local e = {
        x = math.random(20, screen.w - 20),
        y = -30,
        w = 28,
        h = 28,
        speed = 60 + math.random() * 80,
        hp = 1
    }
    table.insert(enemies, e)
end

-- --------------------------
-- LOVE callbacks
-- --------------------------
function love.load()
    math.randomseed(os.time())
    love.window.setMode(screen.w, screen.h, {resizable = false})
    love.window.setTitle("Love2D Single-File Starter — shooter")
    love.graphics.setDefaultFilter("nearest", "nearest")
    font = love.graphics.newFont(14)

    Player.init(screen.w / 2, screen.h - 60)
    Bullets.init()

    score = 0
    enemies = {}
    enemySpawnTimer = 0
    enemySpawnInterval = 2
end

function love.update(dt)
    -- spawn enemies (difficulty ramps down interval slowly)
    enemySpawnTimer = enemySpawnTimer + dt
    if enemySpawnTimer >= enemySpawnInterval then
        spawnEnemy()
        enemySpawnTimer = enemySpawnTimer - enemySpawnInterval
        if enemySpawnInterval > 0.6 then
            enemySpawnInterval = enemySpawnInterval - 0.02
        end
    end

    Player.update(dt)
    Bullets.update(dt)

    -- update enemies
    for i = #enemies, 1, -1 do
        local e = enemies[i]
        e.y = e.y + e.speed * dt

        -- collision with player
        if rectsOverlap(e, Player) then
            -- simple response: reset player position and reduce score
            Player.x = screen.w / 2 - Player.w / 2
            Player.y = screen.h - 60 - Player.h / 2
            score = math.max(0, score - 5)
            table.remove(enemies, i)
        end

        -- remove off-screen enemies
        if e.y > screen.h + 40 then
            table.remove(enemies, i)
        end
    end

    -- bullet-enemy collisions
    for bi = #Bullets.list, 1, -1 do
        local b = Bullets.list[bi]
        for ei = #enemies, 1, -1 do
            local e = enemies[ei]
            if rectsOverlap(b, e) then
                e.hp = e.hp - 1
                table.remove(Bullets.list, bi)
                if e.hp <= 0 then
                    score = score + 1
                    table.remove(enemies, ei)
                end
                break
            end
        end
    end
end

function love.draw()
    love.graphics.setFont(font)

    -- background
    love.graphics.clear(0.09, 0.09, 0.14)

    -- draw player and bullets
    Player.draw()
    Bullets.draw()

    -- draw enemies
    for _, e in ipairs(enemies) do
        love.graphics.setColor(0.9, 0.35, 0.35)
        love.graphics.rectangle("fill", e.x, e.y, e.w, e.h)
        love.graphics.setColor(1,1,1)
    end

    -- HUD
    love.graphics.setColor(1,1,1)
    love.graphics.print("Score: " .. tostring(score), 8, 8)
    love.graphics.print("Use WASD / arrow keys to move. Space to shoot. Esc to quit.", 8, 28)
end

function love.keypressed(key)
    if key == "space" then
        Player.shoot()
    elseif key == "escape" then
        love.event.quit()
    end
end