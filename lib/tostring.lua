function table.tostring(self)
    local s = "{"
    for k, v in pairs(self) do
        if #s > 1 then
            s = s .. ","
        end
        s = s .. tostring(k) .. "="
        if type(v) == "function" then
            s = s .. "()"
        elseif type(v) == "table" then
            s = s .. "{}"
        else
            s = s .. tostring(v)
        end
    end
    return s .. "}"
end
