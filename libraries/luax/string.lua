-- Lua eXtended -- string

local function string_contains(self, str)
    if type(self) ~= "string" or type(str) ~= "string" then return false end
    if str == "" then return true end
    return self:find(str, 1, true) ~= nil
end
if not string.contains then string.contains = string_contains end

function string_starts(self, prefix)
    if type(self) ~= "string" or type(prefix) ~= "string" then return false end
    if prefix == "" then return true end
    return self:sub(1, #prefix) == prefix
end
if not string.starts then string.starts = string_starts end

local function string_ends(self, suffix)
    if type(self) ~= "string" or type(suffix) ~= "string" then return false end
    if suffix == "" then return true end
    local n = #suffix
    if n > #self then return false end
    return self:sub(-n) == suffix
end
if not string.ends then string.ends = string_ends end

local function string_trim(self)
    assert(type(self) == "string")
    return s:match("^%s*(.-)%s*$")
end
if not string.trim then string.trim = string_trim end

local function string_title(self)
    self = self:gsub("%s%l", string.upper)
    self = self:gsub("^%l", string.upper)
    return self
end
if not string.title then string.title = string_title end
