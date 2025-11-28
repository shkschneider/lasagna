local Love = require "core.love"
local Object = require "core.object"
local Lore = require "data.lore"

local Lore = Object {
    id = "lore",
    priority = 200,
    points = 0,
}

function Lore.load(self)
    self.ages = Lore.Ages
    self.messages = Lore.Messages
    self.points = 0
    Love.load(self)
end

return Lore
