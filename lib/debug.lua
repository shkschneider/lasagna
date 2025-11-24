function DEBUG(level)
    level = (level or 1) + 1 -- +1 to account for this function's own stack frame
    local info = debug.getinfo(level, "nSl")
    local fname = info.short_src or "?"
    local line = info.currentline or "?"
    local method = info.name or "?"
    print(string.format("%s:%d %s()", fname, line, method))
end
