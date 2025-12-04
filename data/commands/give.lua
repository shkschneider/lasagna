local CommandsRegistry = require "src.registries.commands"
local BlocksRegistry = require "src.registries.blocks"
local ItemsRegistry = require "src.registries.items"
local Stack = require "src.entities.stack"

CommandsRegistry:register({
    name = "give",
    description = "Give items or blocks to player",
    execute = function(args)
        if not G.debug then return false, nil end

        -- Parse arguments: /give me [itemOrBlock] [quantity]
        if #args < 2 then
            return false, "Usage: /give me <name|id> [quantity]"
        end

        local target = args[1]
        if target ~= "me" then
            return false, "Only 'me' is supported as target"
        end

        -- Try to parse as numeric ID first, otherwise search by name
        local id = tonumber(args[2])
        local search_name = nil
        if not id then
            search_name = args[2]:lower()
        end

        local quantity = 1
        if args[3] then
            quantity = tonumber(args[3])
            if not quantity or quantity < 1 then
                return false, "Invalid quantity: " .. tostring(args[3])
            end
        end

        -- If we have a name, search for it in both registries
        local is_block = false
        local is_item = false
        if search_name then
            -- Search in blocks
            for block_id, block in BlocksRegistry:iterate() do
                if type(block) == "table" and type(block_id) == "number" and block.name then
                    if block.name:lower() == search_name then
                        id = block_id
                        is_block = true
                        break
                    end
                end
            end
            
            -- Search in items (prefer items over blocks if both match)
            for item_id, item in ItemsRegistry:iterate() do
                if type(item) == "table" and type(item_id) == "number" and item.name then
                    if item.name:lower() == search_name then
                        id = item_id
                        is_item = true
                        is_block = false  -- Item takes precedence
                        break
                    end
                end
            end
            
            if not id then
                return false, "Unknown item or block name: " .. tostring(args[2])
            end
        else
            -- Check if it's a block or item by ID
            is_block = BlocksRegistry:exists(id)
            is_item = ItemsRegistry:exists(id)
        end

        if not is_block and not is_item then
            return false, "Unknown item or block: " .. tostring(args[2])
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
            local registry = is_item and ItemsRegistry or BlocksRegistry
            local def = registry:get(id)
            local item_name = (def and def.name) or tostring(id)
            return true, string.format("Gave %d x %s (%s)", quantity, item_name, type_name)
        else
            return false, "Inventory full"
        end
    end,
})
