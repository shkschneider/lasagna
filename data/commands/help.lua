local CommandsRegistry = require "src.game.registries.commands"

CommandsRegistry:register({
    name = "help",
    description = "Lists commands",
    execute = function(args)
        local commands = {}
        for _, command in pairs(CommandsRegistry) do
            if type(command) == "table" then
                table.insert(commands, string.format("/%s: %s", command.name, command.description))
            end
        end
        return true, table.concat(commands, "\n")
    end,
})
