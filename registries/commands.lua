-- Command Registry
-- Commands register themselves here for chat expansion

local CommandsRegistry = {}

-- Register a new command
function CommandsRegistry.register(self, definition)
    assert(definition.name, "Command must have a name")
    assert(definition.execute, "Command must have an execute function")
    assert(not self:exists(definition.name), "Command already exists: " .. tostring(definition.name))
    self[definition.name] = definition
    return definition.name
end

-- Get a command by name
function CommandsRegistry.get(self, name)
    return self[name]
end

-- Execute a command
function CommandsRegistry.execute(self, name, args)
    local command = self:get(name)
    if command then
        return command.execute(args)
    end
    return false, "Unknown command: " .. tostring(name)
end

-- Check if a command exists
function CommandsRegistry.exists(self, name)
    return self[name] ~= nil
end

return CommandsRegistry
