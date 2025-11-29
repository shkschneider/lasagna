local CommandsRegistry = require "src.registries.commands"

local here = (...):gsub("%.init$", "") .. "."

require(here .. "god")
require(here .. "heal")
require(here .. "kill")
require(here .. "ping")
require(here .. "reset")
require(here .. "seed")
require(here .. "teleport")

return CommandsRegistry
