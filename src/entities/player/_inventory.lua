local Love = require "core.love"
local Stack = require "src.entities.stack"

function Player.keypressed(self, key)
    if key == "tab" then
        self.inventory_open = not self.inventory_open
    else
        Love.keypressed(self, key)
    end
end

-- Inventory management - delegates to Inventory
-- Blocks go to backpack first, then hotbar
function Player.add_to_inventory(self, block_id, count)
    local stack = Stack.new(block_id, count or 1, "block")
    -- Try backpack first for blocks
    if self.backpack:can_take(stack) then
        return self.backpack:take(stack)
    end
    -- Try hotbar as fallback
    if self.hotbar:can_take(stack) then
        return self.hotbar:take(stack)
    end
    return false
end

-- Items go to hotbar first, then backpack
function Player.add_item_to_inventory(self, item_id, count)
    local stack = Stack.new(item_id, count or 1, "item")
    -- Try hotbar first for items
    if self.hotbar:can_take(stack) then
        return self.hotbar:take(stack)
    end
    -- Try backpack as fallback
    if self.backpack:can_take(stack) then
        return self.backpack:take(stack)
    end
    return false
end

function Player.remove_from_selected(self, count)
    return self.hotbar:remove_from_selected(count)
end

function Player.get_selected_block_id(self)
    local slot = self.hotbar:get_selected()
    if slot then
        return slot.block_id
    end
    return nil
end
