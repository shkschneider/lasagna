local Fonts = {}

function Fonts.load(self, callback)
    local size = 15
    self.Thin = love.graphics.newFont("assets/fonts/Outfit-Thin.ttf", size)
    self.Regular = love.graphics.newFont("assets/fonts/Outfit-Regular.ttf", size)
    self.Bold = love.graphics.newFont("assets/fonts/Outfit-Bold.ttf", size)
    if callback then callback(self) end
end

function Fonts.set(self, font)
    assert(font)
    love.graphics.setFont(font)
end

return Fonts
