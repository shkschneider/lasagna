-- Inventory Component
-- Manages item storage

local Inventory = {}

function Inventory.new()
    return {
        slots = {},
        selected_slot = 1,
        hotbar_size = 9,
        max_stack = 64,
    }
end

return Inventory
