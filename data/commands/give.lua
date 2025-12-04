local CommandsRegistry = require "src.registries.commands"
local Registry = require "src.registries"
local Stack = require "src.entities.stack"

CommandsRegistry:register({
    name = "give",
    description = "Give items or blocks to player",
    execute = function(args)
        if not G.debug then return false, nil end
        
        -- Parse arguments: /give me [itemOrBlock] [quantity]
        if #args < 2 then
            return false, "Usage: /give me <id> [quantity]"
        end
        
        local target = args[1]
        if target ~= "me" then
            return false, "Only 'me' is supported as target"
        end
        
        local id = tonumber(args[2])
        if not id then
            return false, "Invalid ID: " .. tostring(args[2])
        end
        
        local quantity = 1
        if args[3] then
            quantity = tonumber(args[3])
            if not quantity or quantity < 1 then
                return false, "Invalid quantity: " .. tostring(args[3])
            end
        end
        
        -- Check if it's a block or item
        local is_block = Registry.Blocks:exists(id)
        local is_item = Registry.Items:exists(id)
        
        if not is_block and not is_item then
            return false, "Unknown item or block ID: " .. tostring(id)
        end
        
        -- Add to player inventory
        -- Prefer items over blocks when both exist (items are more specific)
        -- Handle quantities > 64 by adding in chunks
        local success = true
        local remaining = quantity
        while remaining > 0 and success do
            local to_add = math.min(remaining, 64)
            if is_item then
                success = G.player:add_item_to_inventory(id, to_add)
            else
                success = G.player:add_to_inventory(id, to_add)
            end
            remaining = remaining - to_add
        end
        
        if success then
            local type_name = is_item and "item" or "block"
            return true, string.format("Gave %d x %s %d", quantity, type_name, id)
        else
            return false, "Inventory full"
        end
    end,
})
