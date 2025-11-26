-- JSON utility module for loading and parsing JSON files
local rxi_json = require "libraries.rxi.json"

local json = {}

-- Cache for loaded files
local file_cache = {}

-- Load and parse a JSON file
-- Returns the parsed Lua table
function json.load(path)
    -- Check cache first
    if file_cache[path] then
        return file_cache[path]
    end

    local contents, err = love.filesystem.read(path)
    if not contents then
        error("Failed to load " .. path .. ": " .. tostring(err))
    end

    local data = rxi_json.decode(contents)
    file_cache[path] = data
    return data
end

-- Clear the file cache
function json.clear_cache()
    file_cache = {}
end

-- Encode a Lua table to JSON string
function json.encode(data)
    return rxi_json.encode(data)
end

-- Decode a JSON string to Lua table
function json.decode(str)
    return rxi_json.decode(str)
end

return json
