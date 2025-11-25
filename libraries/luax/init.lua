-- Lua eXtended

local here = (...):gsub("%.init$", "") .. "."
-- independant of folder structure
require(here .. "id")
require(here .. "math")
require(here .. "random")
require(here .. "string")
require(here .. "table")
