local Lore = {}

local here = (...):gsub("%.init$", "") .. "."

Lore.Ages = require(here .. "ages")
Lore.Messages = require(here .. "messages")

return Lore
