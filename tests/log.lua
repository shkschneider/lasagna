Log = require "libs.log"
Log.colors = true

local function test(level)
    Log.level = level
    Log.verbose("Hello!")
    Log.debug("It works")
    Log.info("Does", "that", "work?")
    Log.warning(string.format("Apparently: %s...", "so"))
    Log.error("!1")
end

for i = 0, #Log.levels + 1 do
    print("", i)
    test(i)
end
