-- World Features Initialization
-- Loads all feature definitions from this directory

local here = (...):gsub("%.init$", "") .. "."

require(here .. "tree")
