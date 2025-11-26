local here = (...):gsub("%.init$", "") .. "."
return function(column_data, col, z, base_height, world_height)
    require(here .. "ores")(column_data, col, z, base_height, world_height)
end
