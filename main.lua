-- Lasagna Stacking Game
-- A simple game where you stack lasagna ingredients

-- Game state
local gameState = "menu" -- menu, playing, gameover
local score = 0
local lives = 3
local gameSpeed = 100
local speedIncrease = 10

-- Player/plate position
local plateX = 400
local plateY = 500
local plateWidth = 100
local plateHeight = 20

-- Falling ingredient
local ingredient = {
    x = 0,
    y = 50,
    width = 80,
    height = 20,
    speed = gameSpeed,
    direction = 1, -- 1 for right, -1 for left
    type = "pasta"
}

-- Ingredient types and colors
local ingredientTypes = {
    pasta = {r = 1, g = 0.9, b = 0.5},
    sauce = {r = 0.8, g = 0.1, b = 0.1},
    cheese = {r = 1, g = 1, b = 0.7},
    meat = {r = 0.6, g = 0.3, b = 0.2}
}

local ingredientNames = {"pasta", "sauce", "cheese", "meat"}

-- Stack of successfully placed ingredients
local stack = {}
local maxStackHeight = 10

function love.load()
    love.window.setTitle("Lasagna - Stack the Layers!")
    math.randomseed(os.time())
    resetGame()
end

function resetGame()
    score = 0
    lives = 3
    gameSpeed = 100
    stack = {}
    
    -- Add the plate to the stack
    table.insert(stack, {
        x = plateX - plateWidth/2,
        y = plateY,
        width = plateWidth,
        type = "plate"
    })
    
    spawnIngredient()
end

function spawnIngredient()
    local randomType = ingredientNames[math.random(#ingredientNames)]
    ingredient.type = randomType
    ingredient.y = 50
    ingredient.x = math.random(100, 700)
    ingredient.speed = gameSpeed
    ingredient.direction = math.random() > 0.5 and 1 or -1
    
    -- Set width based on stack
    if #stack > 0 then
        local topPiece = stack[#stack]
        ingredient.width = math.max(40, topPiece.width - 5)
    else
        ingredient.width = 80
    end
end

function love.update(dt)
    if gameState == "playing" then
        -- Move ingredient horizontally
        ingredient.x = ingredient.x + ingredient.speed * ingredient.direction * dt
        
        -- Bounce off walls
        if ingredient.x <= 0 or ingredient.x + ingredient.width >= love.graphics.getWidth() then
            ingredient.direction = -ingredient.direction
        end
        
    elseif gameState == "menu" then
        -- Menu updates
    elseif gameState == "gameover" then
        -- Game over updates
    end
end

function love.keypressed(key)
    if gameState == "menu" then
        if key == "space" or key == "return" then
            gameState = "playing"
        elseif key == "escape" then
            love.event.quit()
        end
    elseif gameState == "playing" then
        if key == "space" then
            dropIngredient()
        elseif key == "escape" then
            gameState = "menu"
            resetGame()
        end
    elseif gameState == "gameover" then
        if key == "space" or key == "return" then
            gameState = "menu"
            resetGame()
        elseif key == "escape" then
            love.event.quit()
        end
    end
end

function dropIngredient()
    if #stack == 0 then return end
    
    local topPiece = stack[#stack]
    local targetX = topPiece.x + topPiece.width / 2
    local ingredientCenter = ingredient.x + ingredient.width / 2
    
    -- Calculate overlap
    local leftEdge = math.max(ingredient.x, topPiece.x)
    local rightEdge = math.min(ingredient.x + ingredient.width, topPiece.x + topPiece.width)
    local overlap = rightEdge - leftEdge
    
    if overlap > 20 then
        -- Successful placement
        local newPiece = {
            x = leftEdge,
            y = topPiece.y - ingredient.height,
            width = overlap,
            type = ingredient.type
        }
        table.insert(stack, newPiece)
        score = score + 10
        
        -- Increase difficulty
        gameSpeed = gameSpeed + speedIncrease
        
        -- Check if stack is too tall
        if #stack >= maxStackHeight + 1 then
            gameState = "gameover"
        else
            spawnIngredient()
        end
    else
        -- Missed
        lives = lives - 1
        if lives <= 0 then
            gameState = "gameover"
        else
            spawnIngredient()
        end
    end
end

function love.draw()
    love.graphics.clear(0.2, 0.2, 0.3)
    
    if gameState == "menu" then
        drawMenu()
    elseif gameState == "playing" then
        drawGame()
    elseif gameState == "gameover" then
        drawGameOver()
    end
end

function drawMenu()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("LASAGNA", 0, 150, love.graphics.getWidth(), "center")
    love.graphics.printf("Stack the Layers!", 0, 200, love.graphics.getWidth(), "center")
    love.graphics.printf("Press SPACE to Start", 0, 300, love.graphics.getWidth(), "center")
    love.graphics.printf("Press SPACE to drop ingredients", 0, 350, love.graphics.getWidth(), "center")
    love.graphics.printf("Stack as high as you can!", 0, 380, love.graphics.getWidth(), "center")
    love.graphics.printf("Press ESC to Quit", 0, 450, love.graphics.getWidth(), "center")
end

function drawGame()
    -- Draw falling ingredient
    local color = ingredientTypes[ingredient.type]
    love.graphics.setColor(color.r, color.g, color.b)
    love.graphics.rectangle("fill", ingredient.x, ingredient.y, ingredient.width, ingredient.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", ingredient.x, ingredient.y, ingredient.width, ingredient.height)
    
    -- Draw stack
    for i, piece in ipairs(stack) do
        if piece.type == "plate" then
            love.graphics.setColor(0.5, 0.5, 0.5)
        else
            local color = ingredientTypes[piece.type]
            love.graphics.setColor(color.r, color.g, color.b)
        end
        love.graphics.rectangle("fill", piece.x, piece.y, piece.width, piece.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", piece.x, piece.y, piece.width, piece.height)
    end
    
    -- Draw UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
    love.graphics.print("Lives: " .. lives, 10, 30)
    love.graphics.print("Press SPACE to drop", 10, 50)
    love.graphics.print("Press ESC for menu", 10, 70)
end

function drawGameOver()
    -- Draw final stack
    for i, piece in ipairs(stack) do
        if piece.type == "plate" then
            love.graphics.setColor(0.5, 0.5, 0.5)
        else
            local color = ingredientTypes[piece.type]
            love.graphics.setColor(color.r, color.g, color.b)
        end
        love.graphics.rectangle("fill", piece.x, piece.y, piece.width, piece.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", piece.x, piece.y, piece.width, piece.height)
    end
    
    -- Draw game over text
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 150, 200, 500, 200)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 150, 200, 500, 200)
    love.graphics.printf("GAME OVER", 0, 230, love.graphics.getWidth(), "center")
    love.graphics.printf("Final Score: " .. score, 0, 270, love.graphics.getWidth(), "center")
    love.graphics.printf("Layers Stacked: " .. (#stack - 1), 0, 300, love.graphics.getWidth(), "center")
    love.graphics.printf("Press SPACE to Restart", 0, 340, love.graphics.getWidth(), "center")
end
