require "lib"
local log = require "lib.log"
local Object = require "core.object"

local Systems = {}

function Systems.get(name)
    return G[name]
end

function Systems.iterate(self)
    local list = {}
    for id, object in pairs(self) do
        if type(object) == "table" and Object.is(object) then
            list[#list + 1] = object
        end
    end
    table.sort(list, function(a, b)
        return (a.priority or INFINITY) < (b.priority or INFINITY)
    end)
    local i = 0
    return function()
        i = i + 1
        local object = list[i]
        if object then
            return object.id, object
        end
    end
end

function Systems.load(systems, seed, debug)
    local ordered = {}
    for id, system in pairs(systems) do
        if type(system) == "table" and Object.is(system) then
            system.__id = id
            table.insert(ordered, system)
        end
    end
    table.sort(ordered, function(a, b)
        return (a.priority or INFINITY) < (b.priority or INFINITY)
    end)
    local x, y, z
    for _, system in ipairs(ordered) do
        local id = system.__id
        if type(system.load) == "function" then
            print(id)
            if id == "world" then
                system:load(seed, debug)
                x, y, z = system:find_spawn_position(LAYER_DEFAULT)
            elseif id == "player" then
                system:load(x, y, z)
            elseif id == "camera" then
                system:load(x, y)
            else
                system:load(seed, debug)
            end
        end
    end
    -- for id, system in Systems.iterate(systems) do
    --     assert(id)
    --     log.debug(string.format("%f system: %s", love.timer.getTime(), id))
    --     if id == "world" then
    --         system:load(seed, debug)
    --         x, y, z = system:find_spawn_position(0)
    --     elseif id == "player" then
    --         assert(x and y and z)
    --         system:load(x, y, z)
    --     elseif id == "camera" then
    --         assert(x and y)
    --         system:load(x, y)
    --     elseif type(system.load) == "function" then
    --         system:load(seed, debug)
    --     else
    --         log.warn("System", id, "without load()")
    --     end
    -- end
end

return Systems
