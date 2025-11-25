local CommandsRegistry = require "registries.commands"

local here = (...):gsub("%.init$", "") .. "."
require(here .. "god")
require(here .. "heal")
require(here .. "ping")
require(here .. "seed")
require(here .. "teleport")

return CommandsRegistry
