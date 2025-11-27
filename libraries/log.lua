local Log = {
    colors = true,
}

Log.levels = {
    -- debug
    { name = "verbose", color = "\27[2;34m" }, -- blue (dim)
    { name = "debug",   color = "\27[0;34m" }, -- blue
    -- release
    { name = "info",    color = "\27[0;32m" }, -- green
    { name = "warning", color = "\27[0;33m" }, -- yellow
    { name = "error",   color = "\27[1;31m" }, -- red (bold)
}
-- Log.level = 0 -- all
-- Log.level = 1 -- debug
Log.level = 3 -- release

local function caller()
    if not debug or not debug.getinfo then return "?" end
    local info = debug.getinfo(3, "Sl")
    if not info then return "?" end
    local src = info.short_src or info.source or "?"
    local line = info.currentline or 0
    return string.format("%s:%d", src, line)
end

local function location(path)
    if not path or path == "" then return "" end
    path = path:gsub("\\", "/"):gsub("/+$", "")
    local line = path:match(":(%d+)$")
    path = path:sub(1, #path - #line - 1 - 4)
    local dirname, basename = path:match("^(.*)/([^/]+)$")
    if not basename then dirname, basename = nil, path end
    return string.format("%s%s:%s", dirname and #dirname and "[" .. dirname .. "] " or "", basename, line)
end

-- Log.debug/verbose/info/warning/error
for i, level in pairs(Log.levels) do
    Log[string.lower(level.name)] = function(...)
        if i < #Log.levels and i < Log.level then
            return
        end
        local datetime = love and string.format("%.09f", love.timer.getTime()) or os.date("%H:%M:%S")
        local tag = string.format("%s %s %s: ", datetime, string.upper(level.name), location(caller()))
        print(
            (Log.colors and level.color or "")
            .. tag
            .. (Log.colors and "\27[0m" or "")
            .. table.concat({...} or {}, " ")
        )
    end
end

return Log
