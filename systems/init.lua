local log = require "lib.log"

local Systems = {}

function Systems.get(name)
    return G.systems[name]
end

function Systems.load(systems, seed)
    local ordered = {}
    for id, system in Systems.iterate(systems) do
        assert(id)
        log.debug("system:", id)
        if id == "world" then
            system:load(seed)
            x, y, z = system:find_spawn_position(math.floor(system.WIDTH / 2), 0)
        elseif id == "player" then
            assert(x and y and z)
            system:load(x, y, z)
        elseif id == "camera" then
            assert(x and y)
            system:load(x, y)
        elseif type(system.load) == "function" then
            system:load()
        else
            log.warn("System", id, "without load()")
        end
    end
end

function Systems.iterate(systems)
    local list = {}
    for id, system in pairs(systems) do
        list[#list + 1] = system
    end
    table.sort(list, function(a, b)
        return (a.priority or 1e9) < (b.priority or 1e9)
    end)
    local i = 0
    return function()
        i = i + 1
        local system = list[i]
        if system then
            return system.id, system
        end
    end
end

return Systems
