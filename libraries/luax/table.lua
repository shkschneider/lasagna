-- Lua eXtended -- table

if not table.pack then
    table.pack = function(...) return { n = select("#", ...), ... } end
end
if not table.unpack then
    table.unpack = unpack
end

local function table_isarray(self)
    if type(self) ~= "table" then return false end
    if next(self) == nil then return true end
    if self[1] == nil then return false end
    for key, _ in pairs(self) do
        if type(key) ~= "number" then
            return false
        end
    end
    return true
end
if not table.isarray then table.isarray = table_isarray end

local function table_tostring(self)
    local function _table_tostring(self)
        local str = "{"
        for key, value in pairs(self) do
            if #str > 1 then str = str .. "," end
            str = str .. tostring(key) .. "="
            if type(value) == "function" then
                str = str .. "()"
            elseif type(value) == "table" then
                str = str .. (table.isarray(value) and "[]" or "{}")
            else
                str = str .. tostring(value)
            end
        end
        return str .. "}"
    end
    local function _array_tostring(self)
        local str = "["
        for _, value in ipairs(self) do
            if #str > 1 then str = str .. "," end
            str = str .. tostring(value)
        end
        return str .. "]"
    end
    if table.isarray(self) then
        return _array_tostring(self)
    else
        return _table_tostring(self)
    end
end
if not table.tostring then table.tostring = table_tostring end

local function table_random(self)
    return self[random(#self)]
end
if not table.random then table.random = table_random end

local function table_keys(self)
    if table.isarray(self) then return nil end
    local keys = {} -- array
    for key, _ in pairs(self) do
        table.insert(keys, key)
    end
    return keys
end
if not table.keys then table.keys = table_keys end

local function table_unique(self)
    -- TODO check value if array but check key if table
	local seen = {}
	local uniques = {}
	for _, value in ipairs(self) do
		if not seen[value] then
			seen[value] = true
			table.insert(uniques, value)
		end
	end
	return uniques
end
if not table.unique then table.unique = table_unique end

-- suppports (negative) indexes
local function table_get(self, i)
    if type(self) ~= "table" then return nil end
    local idx = tonumber(i)
    if not idx then return nil end
    if idx == 0 then return nil end
    if idx > 0 then return self[idx] end -- normal
    -- for negative indexes, take from the end
    local len = 0
    for key, _ in pairs(self) do
        if type(key) == "number" and key >= 1 then
            if key == math.floor(key) and key > len then
                len = key
            end
        end
    end
    if len == 0 then return nil end
    i = len + 1 + idx -- converted
    if i < 1 then return nil end
    return self[i]
end
if not table.get then table.get = table_get end
