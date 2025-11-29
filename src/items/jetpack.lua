local Love = require "core.love"
local Object = require "core.object"

local Jetpack = Object {
    id = "jetpack",
    priority = 61,
}

function Jetpack.load(self)
    Love.load(self)
end

return Jetpack
