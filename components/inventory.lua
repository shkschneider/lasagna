-- Inventory component
-- Item storage data

local InventoryComponent = {}

function InventoryComponent.new(hotbar_size, max_stack)
    return {
        id = "inventory",
        slots = {},
        selected_slot = 1,
        hotbar_size = hotbar_size or 9,
        max_stack = max_stack or STACK_SIZE,
    }
end

return InventoryComponent
