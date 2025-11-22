-- Inventory component
-- Item storage data

local Inventory = {}

function Inventory.new(hotbar_size, max_stack)
    return {
        slots = {},
        selected_slot = 1,
        hotbar_size = hotbar_size or 9,
        max_stack = max_stack or 64,
    }
end

return Inventory
