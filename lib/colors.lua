local Colors = {}

function Colors.hex2rgb(hex)
    local hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255
end

Colors.Aqua = hex2rgb("#00ffff")
Colors.Black = hex2rgb("#000000")
Colors.Blue = hex2rgb("#0000ff")
Colors.Fuchsia = hex2rgb("#ff00ff")
Colors.Gray = hex2rgb("#808080")
Colors.Green = hex2rgb("#009900")
Colors.Lime = hex2rgb("#00f00")
Colors.Maroon = hex2rgb("#990000")
Colors.Navy = hex2rgb("#000080")
Colors.Olive = hex2rgb("#808000")
Colors.Purple = hex2rgb("#800080")
Colors.Red = hex2rgb("#ff0000")
Colors.Silver = hex2rgb("#c0c0c0")
Colors.Teal = hex2rgb("#006666")
Colors.White = hex2rgb("#ffffff")
Colors.Yellow = hex2rgb("#ffff00")

return Colors
