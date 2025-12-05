-- Default block definitions
-- Blocks register themselves with the BlocksRegistry

local here = (...):gsub("%.init$", "") .. "."

require(here .. "base")
require(here .. "ores")
require(here .. "machines")

return require(here .. "ids")
