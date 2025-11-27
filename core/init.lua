-- macro-like
function DEBUG(level)
    -- +1 to account for this function's own stack frame
    level = (level or 1) + 1
    local info = debug.getinfo(level, "nSl")
    local fname = info.short_src or "?"
    local line = info.currentline or "?"
    local method = info.name or "?"
    print(string.format("%s:%d %s()", fname, line, method))
end
