return function(template, data)
    assert(type(template) == "string")
    data = data or {}
    assert(type(data) == "table")
    -- non-greedy capture of the key, trim surrounding whitespace
    local str = template:gsub("{{%s*(.-)%s*}}", function(key)
        -- follow dot-separated parts in data table
        local d = data
        for part in key:gmatch("[^%.]+") do
            if type(d) ~= "table" then
                d = nil
                break
            end
            d = d[part]
        end
        return d and tostring(d) or ""
    end)
    return str
end
