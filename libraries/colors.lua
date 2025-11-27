-- https://lospec.com/palette-list/resurrect-64
-- Organized with base16-inspired color names

local Colors = {}

function Colors.hex2rgb(hex)
    local hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255
end

-- Base colors grouped by 3 tones (dark, normal, light)

-- Neutrals
Colors.black = {
    dark = {Colors.hex2rgb("#2e222f")},
    normal = {Colors.hex2rgb("#3e3546")},
    light = {Colors.hex2rgb("#625565")}
}

Colors.gray = {
    dark = {Colors.hex2rgb("#694f62")},
    normal = {Colors.hex2rgb("#7f708a")},
    light = {Colors.hex2rgb("#9babb2")}
}

Colors.white = {
    dark = {Colors.hex2rgb("#c7dcd0")},
    normal = {Colors.hex2rgb("#ffffff")},
    light = {Colors.hex2rgb("#ffffff")}
}

-- Warm colors
Colors.red = {
    dark = {Colors.hex2rgb("#6e2727")},
    normal = {Colors.hex2rgb("#e83b3b")},
    light = {Colors.hex2rgb("#f68181")}
}

Colors.orange = {
    dark = {Colors.hex2rgb("#9e4539")},
    normal = {Colors.hex2rgb("#fb6b1d")},
    light = {Colors.hex2rgb("#f57d4a")}
}

Colors.yellow = {
    dark = {Colors.hex2rgb("#676633")},
    normal = {Colors.hex2rgb("#f9c22b")},
    light = {Colors.hex2rgb("#fbff86")}
}

Colors.brown = {
    dark = {Colors.hex2rgb("#4c3e24")},
    normal = {Colors.hex2rgb("#ab947a")},
    light = {Colors.hex2rgb("#fdcbb0")}
}

-- Cool colors
Colors.green = {
    dark = {Colors.hex2rgb("#165a4c")},
    normal = {Colors.hex2rgb("#1ebc73")},
    light = {Colors.hex2rgb("#91db69")}
}

Colors.cyan = {
    dark = {Colors.hex2rgb("#0b5e65")},
    normal = {Colors.hex2rgb("#0eaf9b")},
    light = {Colors.hex2rgb("#8ff8e2")}
}

Colors.blue = {
    dark = {Colors.hex2rgb("#323353")},
    normal = {Colors.hex2rgb("#4d9be6")},
    light = {Colors.hex2rgb("#8fd3ff")}
}

Colors.purple = {
    dark = {Colors.hex2rgb("#6b3e75")},
    normal = {Colors.hex2rgb("#905ea9")},
    light = {Colors.hex2rgb("#eaaded")}
}

Colors.magenta = {
    dark = {Colors.hex2rgb("#831c5d")},
    normal = {Colors.hex2rgb("#c32454")},
    light = {Colors.hex2rgb("#f04f78")}
}

Colors.pink = {
    dark = {Colors.hex2rgb("#753c54")},
    normal = {Colors.hex2rgb("#cf657f")},
    light = {Colors.hex2rgb("#fca790")}
}

return Colors
