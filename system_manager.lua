-- System Manager
-- Manages system lifecycle and execution order

local SystemManager = {
    systems = {},
}

function SystemManager:push(system)
    table.insert(self.systems, system)
    -- Sort systems by priority (lower number = higher priority, runs first)
    table.sort(self.systems, function(a, b)
        return a.priority < b.priority
    end)
end

function SystemManager:load(...)
    for _, system in ipairs(self.systems) do
        if system.load then
            system:load(...)
        end
    end
end

function SystemManager:update(dt)
    for _, system in ipairs(self.systems) do
        if system.update then
            system:update(dt)
        end
    end
end

function SystemManager:draw()
    for _, system in ipairs(self.systems) do
        if system.draw then
            system:draw()
        end
    end
end

function SystemManager:keypressed(key)
    for _, system in ipairs(self.systems) do
        if system.keypressed then
            system:keypressed(key)
        end
    end
end

function SystemManager:mousepressed(x, y, button)
    for _, system in ipairs(self.systems) do
        if system.mousepressed then
            system:mousepressed(x, y, button)
        end
    end
end

function SystemManager:resize(width, height)
    for _, system in ipairs(self.systems) do
        if system.resize then
            system:resize(width, height)
        end
    end
end

return SystemManager
