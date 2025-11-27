local Colors = {}

function Colors.hex2rgb(hex)
    local hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255
end

-- Legacy flat colors (for backwards compatibility)
Colors.Aqua = {Colors.hex2rgb("#00ffff")}
Colors.Black = {Colors.hex2rgb("#000000")}
Colors.Blue = {Colors.hex2rgb("#0000ff")}
Colors.Fuchsia = {Colors.hex2rgb("#ff00ff")}
Colors.Gray = {Colors.hex2rgb("#808080")}
Colors.Green = {Colors.hex2rgb("#009900")}
Colors.Lime = {Colors.hex2rgb("#00ff00")}
Colors.Maroon = {Colors.hex2rgb("#990000")}
Colors.Navy = {Colors.hex2rgb("#000080")}
Colors.Olive = {Colors.hex2rgb("#808000")}
Colors.Purple = {Colors.hex2rgb("#800080")}
Colors.Red = {Colors.hex2rgb("#ff0000")}
Colors.Silver = {Colors.hex2rgb("#c0c0c0")}
Colors.Teal = {Colors.hex2rgb("#006666")}
Colors.White = {Colors.hex2rgb("#ffffff")}
Colors.Yellow = {Colors.hex2rgb("#ffff00")}

-- Palette colors grouped by 3 tones (dark, normal, light)
Colors.black = {
    dark = {Colors.hex2rgb("#2e222f")},
    normal = {Colors.hex2rgb("#3e3546")},
    light = {Colors.hex2rgb("#625565")}
}

Colors.gray = {
    dark = {Colors.hex2rgb("#313638")},
    normal = {Colors.hex2rgb("#7f708a")},
    light = {Colors.hex2rgb("#9babb2")}
}

Colors.white = {
    dark = {Colors.hex2rgb("#c7dcd0")},
    normal = {Colors.hex2rgb("#ffffff")},
    light = {Colors.hex2rgb("#ffffff")}
}

Colors.brown = {
    dark = {Colors.hex2rgb("#4c3e24")},
    normal = {Colors.hex2rgb("#966c6c")},
    light = {Colors.hex2rgb("#ab947a")}
}

Colors.maroon = {
    dark = {Colors.hex2rgb("#6e2727")},
    normal = {Colors.hex2rgb("#b33831")},
    light = {Colors.hex2rgb("#ea4f36")}
}

Colors.red = {
    dark = {Colors.hex2rgb("#ae2334")},
    normal = {Colors.hex2rgb("#e83b3b")},
    light = {Colors.hex2rgb("#f57d4a")}
}

Colors.orange = {
    dark = {Colors.hex2rgb("#fb6b1d")},
    normal = {Colors.hex2rgb("#f79617")},
    light = {Colors.hex2rgb("#f9c22b")}
}

Colors.peach = {
    dark = {Colors.hex2rgb("#9e4539")},
    normal = {Colors.hex2rgb("#cd683d")},
    light = {Colors.hex2rgb("#e6904e")}
}

Colors.tan = {
    dark = {Colors.hex2rgb("#7a3045")},
    normal = {Colors.hex2rgb("#fbb954")},
    light = {Colors.hex2rgb("#fdcbb0")}
}

Colors.olive = {
    dark = {Colors.hex2rgb("#676633")},
    normal = {Colors.hex2rgb("#a2a947")},
    light = {Colors.hex2rgb("#d5e04b")}
}

Colors.yellow = {
    dark = {Colors.hex2rgb("#a2a947")},
    normal = {Colors.hex2rgb("#d5e04b")},
    light = {Colors.hex2rgb("#fbff86")}
}

Colors.lime = {
    dark = {Colors.hex2rgb("#547e64")},
    normal = {Colors.hex2rgb("#92a984")},
    light = {Colors.hex2rgb("#b2ba90")}
}

Colors.green = {
    dark = {Colors.hex2rgb("#165a4c")},
    normal = {Colors.hex2rgb("#239063")},
    light = {Colors.hex2rgb("#1ebc73")}
}

Colors.mint = {
    dark = {Colors.hex2rgb("#91db69")},
    normal = {Colors.hex2rgb("#cddf6c")},
    light = {Colors.hex2rgb("#8ff8e2")}
}

Colors.teal = {
    dark = {Colors.hex2rgb("#0b5e65")},
    normal = {Colors.hex2rgb("#0b8a8f")},
    light = {Colors.hex2rgb("#0eaf9b")}
}

Colors.cyan = {
    dark = {Colors.hex2rgb("#374e4a")},
    normal = {Colors.hex2rgb("#30e1b9")},
    light = {Colors.hex2rgb("#8ff8e2")}
}

Colors.navy = {
    dark = {Colors.hex2rgb("#323353")},
    normal = {Colors.hex2rgb("#484a77")},
    light = {Colors.hex2rgb("#4d65b4")}
}

Colors.blue = {
    dark = {Colors.hex2rgb("#4d65b4")},
    normal = {Colors.hex2rgb("#4d9be6")},
    light = {Colors.hex2rgb("#8fd3ff")}
}

Colors.indigo = {
    dark = {Colors.hex2rgb("#45293f")},
    normal = {Colors.hex2rgb("#6b3e75")},
    light = {Colors.hex2rgb("#905ea9")}
}

Colors.purple = {
    dark = {Colors.hex2rgb("#694f62")},
    normal = {Colors.hex2rgb("#a884f3")},
    light = {Colors.hex2rgb("#eaaded")}
}

Colors.magenta = {
    dark = {Colors.hex2rgb("#831c5d")},
    normal = {Colors.hex2rgb("#c32454")},
    light = {Colors.hex2rgb("#f04f78")}
}

Colors.pink = {
    dark = {Colors.hex2rgb("#753c54")},
    normal = {Colors.hex2rgb("#a24b6f")},
    light = {Colors.hex2rgb("#cf657f")}
}

Colors.rose = {
    dark = {Colors.hex2rgb("#ed8099")},
    normal = {Colors.hex2rgb("#f68181")},
    light = {Colors.hex2rgb("#fca790")}
}

return Colors
