-- Load the binser library
local binser = require("libs.bakpakin.binser")

-- Pretty-print function for tables
local function dump_table(t, indent)
    indent = indent or 0
    local spaces = string.rep("  ", indent)
    local result = "{\n"
    -- Collect and sort keys for consistent output
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        if ta ~= tb then
            return ta < tb
        end
        if ta == "number" or ta == "string" then
            return a < b
        end
        return tostring(a) < tostring(b)
    end)
    for _, k in ipairs(keys) do
        local v = t[k]
        local key_str
        if type(k) == "string" then
            key_str = string.format("[%q]", k)
        else
            key_str = string.format("[%s]", tostring(k))
        end
        result = result .. spaces .. "  " .. key_str .. " = "
        if type(v) == "table" then
            result = result .. dump_table(v, indent + 1)
        elseif type(v) == "string" then
            result = result .. string.format("%q", v)
        elseif type(v) == "number" or type(v) == "boolean" then
            result = result .. tostring(v)
        else
            result = result .. string.format("<%s>", type(v))
        end
        result = result .. ",\n"
    end
    result = result .. spaces .. "}"
    return result
end

if #arg < 1 then
    print("Usage: lua tools/save.lua <path-to-save-file.sav>")
    print("")
    print("This script reads a .sav file and dumps its contents as a formatted table.")
    print("The save file is deserialized using the binser library.")
    os.exit(1)
end

local filepath = arg[1]

-- Check if file exists
local file = io.open(filepath, "rb")
if not file then
    print(string.format("Error: Cannot open file '%s'", filepath))
    os.exit(1)
end

-- Read file contents
local content = file:read("*all")
file:close()

if not content or #content == 0 then
    print(string.format("Error: File '%s' is empty", filepath))
    os.exit(1)
end

-- Deserialize using binser
local success, result, len = pcall(binser.deserialize, content)
if not success then
    print(string.format("Error: Failed to deserialize file '%s'", filepath))
    print(string.format("Details: %s", tostring(result)))
    os.exit(1)
end

-- Result from binser.deserialize is an array of deserialized values
if type(result) ~= "table" then
    print(string.format("Error: Unexpected result type: %s", type(result)))
    os.exit(1)
end

-- Dump each deserialized object
for i, obj in ipairs(result) do
    if type(obj) == "table" then
        print(dump_table(obj, 0))
    else
        print(string.format("  %s: %s", type(obj), tostring(obj)))
    end
end
