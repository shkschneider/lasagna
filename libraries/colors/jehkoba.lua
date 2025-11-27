-- https://lospec.com/palette-list/jehkoba64

local Colors = {}

function Colors.hex2rgb(hex)
    local hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255
end

-- Palette colors grouped by 3 tones (dark, normal, light)
Colors.black = {
    dark = {Colors.hex2rgb("#000000")},
    normal = {Colors.hex2rgb("#050e1a")},
    light = {Colors.hex2rgb("#0d2140")}
}

Colors.gray = {
    dark = {Colors.hex2rgb("#495169")},
    normal = {Colors.hex2rgb("#696570")},
    light = {Colors.hex2rgb("#807980")}
}

Colors.silver = {
    dark = {Colors.hex2rgb("#a69a9c")},
    normal = {Colors.hex2rgb("#c4bbb3")},
    light = {Colors.hex2rgb("#d9a798")}
}

Colors.white = {
    dark = {Colors.hex2rgb("#c4bbb3")},
    normal = {Colors.hex2rgb("#d9a798")},
    light = {Colors.hex2rgb("#f2f2da")}
}

Colors.brown = {
    dark = {Colors.hex2rgb("#472e3e")},
    normal = {Colors.hex2rgb("#6e4250")},
    light = {Colors.hex2rgb("#875d58")}
}

Colors.tan = {
    dark = {Colors.hex2rgb("#875d58")},
    normal = {Colors.hex2rgb("#9e7767")},
    light = {Colors.hex2rgb("#b58c7f")}
}

Colors.maroon = {
    dark = {Colors.hex2rgb("#852264")},
    normal = {Colors.hex2rgb("#c40c2e")},
    light = {Colors.hex2rgb("#f53141")}
}

Colors.red = {
    dark = {Colors.hex2rgb("#c40c2e")},
    normal = {Colors.hex2rgb("#f53141")},
    light = {Colors.hex2rgb("#ff7070")}
}

Colors.coral = {
    dark = {Colors.hex2rgb("#9e4c4c")},
    normal = {Colors.hex2rgb("#fa9891")},
    light = {Colors.hex2rgb("#ff7070")}
}

Colors.orange = {
    dark = {Colors.hex2rgb("#db4b16")},
    normal = {Colors.hex2rgb("#f2621f")},
    light = {Colors.hex2rgb("#f58122")}
}

Colors.peach = {
    dark = {Colors.hex2rgb("#f58122")},
    normal = {Colors.hex2rgb("#faa032")},
    light = {Colors.hex2rgb("#fabbaf")}
}

Colors.gold = {
    dark = {Colors.hex2rgb("#ad6a45")},
    normal = {Colors.hex2rgb("#cc8029")},
    light = {Colors.hex2rgb("#e69b22")}
}

Colors.yellow = {
    dark = {Colors.hex2rgb("#e69b22")},
    normal = {Colors.hex2rgb("#ffb938")},
    light = {Colors.hex2rgb("#fad937")}
}

Colors.olive = {
    dark = {Colors.hex2rgb("#7a5e37")},
    normal = {Colors.hex2rgb("#8c8024")},
    light = {Colors.hex2rgb("#989c27")}
}

Colors.lime = {
    dark = {Colors.hex2rgb("#989c27")},
    normal = {Colors.hex2rgb("#b3b02d")},
    light = {Colors.hex2rgb("#ccc73d")}
}

Colors.green = {
    dark = {Colors.hex2rgb("#068051")},
    normal = {Colors.hex2rgb("#179c43")},
    light = {Colors.hex2rgb("#55b33b")}
}

Colors.grass = {
    dark = {Colors.hex2rgb("#55b33b")},
    normal = {Colors.hex2rgb("#94bf30")},
    light = {Colors.hex2rgb("#ccc73d")}
}

Colors.teal = {
    dark = {Colors.hex2rgb("#116061")},
    normal = {Colors.hex2rgb("#20806c")},
    light = {Colors.hex2rgb("#3da17e")}
}

Colors.mint = {
    dark = {Colors.hex2rgb("#3da17e")},
    normal = {Colors.hex2rgb("#5cb888")},
    light = {Colors.hex2rgb("#7ccf9a")}
}

Colors.cyan = {
    dark = {Colors.hex2rgb("#7ccf9a")},
    normal = {Colors.hex2rgb("#a0eba8")},
    light = {Colors.hex2rgb("#a0eba8")}
}

Colors.sky = {
    dark = {Colors.hex2rgb("#195ba6")},
    normal = {Colors.hex2rgb("#1c75bd")},
    light = {Colors.hex2rgb("#1793e6")}
}

Colors.blue = {
    dark = {Colors.hex2rgb("#1793e6")},
    normal = {Colors.hex2rgb("#25acf5")},
    light = {Colors.hex2rgb("#49c2f2")}
}

Colors.navy = {
    dark = {Colors.hex2rgb("#243966")},
    normal = {Colors.hex2rgb("#3553a6")},
    light = {Colors.hex2rgb("#586ac4")}
}

Colors.indigo = {
    dark = {Colors.hex2rgb("#586ac4")},
    normal = {Colors.hex2rgb("#7e7ef2")},
    light = {Colors.hex2rgb("#ae88e3")}
}

Colors.purple = {
    dark = {Colors.hex2rgb("#4e278c")},
    normal = {Colors.hex2rgb("#773bbf")},
    light = {Colors.hex2rgb("#a35dd9")}
}

Colors.violet = {
    dark = {Colors.hex2rgb("#a35dd9")},
    normal = {Colors.hex2rgb("#ca7ef2")},
    light = {Colors.hex2rgb("#e29bfa")}
}

Colors.magenta = {
    dark = {Colors.hex2rgb("#b32d7d")},
    normal = {Colors.hex2rgb("#d94c8e")},
    light = {Colors.hex2rgb("#eb758f")}
}

Colors.pink = {
    dark = {Colors.hex2rgb("#eb758f")},
    normal = {Colors.hex2rgb("#fabbaf")},
    light = {Colors.hex2rgb("#fabbaf")}
}

return Colors
