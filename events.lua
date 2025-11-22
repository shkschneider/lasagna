local Events = {
    WORLD_GENERATION = "world_generation",
    PLAYER_MINED_BLOCK = "player_mined_block",
    PLAYER_PLACED_BLOCK = "player_placed_block",
}

local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function Events.push(self, type, ...)
    assert(type(type) == "string")
    assert(type(data) == "table")
    table.insert(self, { id = uuid(), type = type, data = {...} })
    table.sort(self, function(a, b) return a.priority or 0 < b.priority or 0 end)
end

-- TODO not tested
function Events.get(self, idOrType)
    assert(type(idOrType) == "string")
    return function()
        for event in ipairs(self) do
            if event.id == idOrType or event.type == idOrType then
                return event
            end
        end
    end
end

function Events.pop(self, id)
    self[id] = nil
end

return Events
