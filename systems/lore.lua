local Object = require "core.object"
local Lore = require "data.lore"

local LoreSystem = Object.new {
    id = "lore",
    priority = 200,
    points = 0,
}

function LoreSystem.load(self)
    self.ages = Lore.Ages
    self.messages = Lore.Messages
    self.points = 0
end

return LoreSystem
