local CommandsRegistry = require "src.registries.commands"

local here = (...):gsub("%.init$", "") .. "."

require(here .. "help")

require(here .. "give")
require(here .. "god")
require(here .. "heal")
require(here .. "kill")
require(here .. "load")
require(here .. "ping")
require(here .. "reset")
require(here .. "save")
require(here .. "seed")
require(here .. "teleport")

return CommandsRegistry
