local Fonts = {}

function Fonts.load(self)
    local size = 15
    self.Thin = love.graphics.newFont("data/fonts/Outfit-Thin.ttf", size)
    self.Regular = love.graphics.newFont("data/fonts/Outfit-Regular.ttf", size)
    self.Bold = love.graphics.newFont("data/fonts/Outfit-Bold.ttf", size)
end

function Fonts.set(self, font)
    assert(font)
    love.graphics.setFont(font)
end

return Fonts
