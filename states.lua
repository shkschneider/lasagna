local States = {
    BOOT = "boot",
    MENU = "menu",
    LOADING = "loading",
    PLAYING = "playing",
    DEAD = "dead",
}

function States.new()
    return {
        state = "unknown",
        debug = false,
    }
end

return States
