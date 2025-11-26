local here = (...):gsub("%.init$", "") .. "."

-- Load feature definitions
require(here .. "features")

return function(column_data, col, z, base_height, world_height)
    require(here .. "ores")(column_data, col, z, base_height, world_height)
    require(here .. "features.generator")(column_data, col, z, base_height, world_height)
end
