-- Item definitions
-- Items register themselves with the ItemsRegistry

local here = (...):gsub("%.init$", "") .. "."

require(here .. "omnitool")
require(here .. "weapons")

return require(here .. "ids")
