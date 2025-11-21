local Colors = {}

function Colors.hex2rgb(hex)
    local hex = hex:gsub("#", "")
    return tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255
end

Colors.Aqua = {Colors.hex2rgb("#00ffff")}
Colors.Black = {Colors.hex2rgb("#000000")}
Colors.Blue = {Colors.hex2rgb("#0000ff")}
Colors.Fuchsia = {Colors.hex2rgb("#ff00ff")}
Colors.Gray = {Colors.hex2rgb("#808080")}
Colors.Green = {Colors.hex2rgb("#009900")}
Colors.Lime = {Colors.hex2rgb("#00f00")}
Colors.Maroon = {Colors.hex2rgb("#990000")}
Colors.Navy = {Colors.hex2rgb("#000080")}
Colors.Olive = {Colors.hex2rgb("#808000")}
Colors.Purple = {Colors.hex2rgb("#800080")}
Colors.Red = {Colors.hex2rgb("#ff0000")}
Colors.Silver = {Colors.hex2rgb("#c0c0c0")}
Colors.Teal = {Colors.hex2rgb("#006666")}
Colors.White = {Colors.hex2rgb("#ffffff")}
Colors.Yellow = {Colors.hex2rgb("#ffff00")}

return Colors
