-- Inventory system
-- Hotbar: 9 slots, stack size 64

local blocks = require("blocks")

local inventory = {}

inventory.HOTBAR_SIZE = 9
inventory.MAX_STACK = 64

function inventory.new()
    local inv = {
        slots = {},
        selected_slot = 1, -- 1-indexed
    }
    
    -- Initialize hotbar slots
    for i = 1, inventory.HOTBAR_SIZE do
        inv.slots[i] = nil
    end
    
    return inv
end

-- Get selected slot data
function inventory.get_selected(inv)
    return inv.slots[inv.selected_slot]
end

-- Get selected block ID (or nil)
function inventory.get_selected_block_id(inv)
    local slot = inv.slots[inv.selected_slot]
    if slot then
        return slot.block_id
    end
    return nil
end

-- Add item to inventory
-- Returns true if successful, false if inventory full
function inventory.add(inv, block_id, count)
    count = count or 1
    
    if count <= 0 then
        return true
    end
    
    -- Try to stack with existing slots first
    for i = 1, inventory.HOTBAR_SIZE do
        local slot = inv.slots[i]
        if slot and slot.block_id == block_id then
            local space = inventory.MAX_STACK - slot.count
            if space > 0 then
                local to_add = math.min(space, count)
                slot.count = slot.count + to_add
                count = count - to_add
                
                if count == 0 then
                    return true
                end
            end
        end
    end
    
    -- Find empty slots
    while count > 0 do
        local empty_slot = nil
        for i = 1, inventory.HOTBAR_SIZE do
            if not inv.slots[i] then
                empty_slot = i
                break
            end
        end
        
        if not empty_slot then
            return false -- Inventory full
        end
        
        local to_add = math.min(inventory.MAX_STACK, count)
        inv.slots[empty_slot] = {
            block_id = block_id,
            count = to_add,
        }
        count = count - to_add
    end
    
    return true
end

-- Remove count from selected slot
-- Returns the actual count removed
function inventory.remove_from_selected(inv, count)
    count = count or 1
    local slot = inv.slots[inv.selected_slot]
    
    if not slot then
        return 0
    end
    
    local removed = math.min(count, slot.count)
    slot.count = slot.count - removed
    
    if slot.count <= 0 then
        inv.slots[inv.selected_slot] = nil
    end
    
    return removed
end

-- Select slot by index (1-9)
function inventory.select_slot(inv, slot_index)
    if slot_index >= 1 and slot_index <= inventory.HOTBAR_SIZE then
        inv.selected_slot = slot_index
    end
end

return inventory
