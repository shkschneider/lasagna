local Object = require("lib.object")

--- InventoryComponent: Manages player inventory with slots and items
--- Items are stored as { proto, count, data } where proto is any table (typically a Block)
--- with optional use function and max_stack field.
---
--- Usage:
---   local Inventory = require("entities.components.inventory")
---   player.inventory = Inventory.new(player, { slots = 9 })
---   player.inventory:add(Blocks.dirt, 10)
---   player.inventory:use_selected({ world = world, x = 10, y = 20 })

local Inventory = Object {}

--- Creates a new Inventory component
--- @param player table The player entity to attach to
--- @param opts table Optional configuration: slots (default 9)
--- @return table Inventory component instance
function Inventory:new(player, opts)
    opts = opts or {}
    
    -- Reference to the player entity
    self.player = player
    
    -- Inventory fields
    self.slots = opts.slots or 9
    self.items = {}  -- Array of { proto, count, data }
    self.selected = 1
    
    -- Initialize empty slots
    for i = 1, self.slots do
        self.items[i] = nil
    end
end

--- Adds items to the inventory
--- @param proto table The item prototype (e.g., a Block)
--- @param count number Amount to add
--- @return number Leftover count that couldn't be added
function Inventory:add(proto, count)
    if not proto or not count or count <= 0 then
        return count or 0
    end
    
    local max_stack = proto.max_stack or 64
    local leftover = count
    
    -- First, try to stack with existing items
    for i = 1, self.slots do
        local slot = self.items[i]
        if slot and slot.proto == proto then
            local space = max_stack - slot.count
            if space > 0 then
                local to_add = math.min(space, leftover)
                slot.count = slot.count + to_add
                leftover = leftover - to_add
                if leftover <= 0 then
                    return 0
                end
            end
        end
    end
    
    -- Then, fill empty slots
    for i = 1, self.slots do
        if not self.items[i] then
            local to_add = math.min(max_stack, leftover)
            self.items[i] = {
                proto = proto,
                count = to_add,
                data = {}
            }
            leftover = leftover - to_add
            if leftover <= 0 then
                return 0
            end
        end
    end
    
    return leftover
end

--- Removes items from a specific slot
--- @param slotIdx number The slot index (1-based)
--- @param count number Amount to remove
--- @return boolean Success
--- @return number Actual amount removed
function Inventory:remove(slotIdx, count)
    if slotIdx < 1 or slotIdx > self.slots then
        return false, 0
    end
    
    local slot = self.items[slotIdx]
    if not slot then
        return false, 0
    end
    
    local to_remove = math.min(count, slot.count)
    slot.count = slot.count - to_remove
    
    if slot.count <= 0 then
        self.items[slotIdx] = nil
    end
    
    return true, to_remove
end

--- Uses the selected item
--- Calls proto.use(player, ctx, slot.data) if it exists, decrements count on success
--- @param ctx table Context for use (e.g., { world, x, y })
--- @return boolean Success
--- @return string Message
function Inventory:use_selected(ctx)
    local slot = self.items[self.selected]
    if not slot then
        return false, "no item selected"
    end
    
    local proto = slot.proto
    if not proto then
        return false, "invalid item"
    end
    
    -- Check if proto has a use function
    if type(proto.use) == "function" then
        local success, err = pcall(proto.use, self.player, ctx, slot.data)
        if success and err ~= false then
            -- Decrement count on successful use
            slot.count = slot.count - 1
            if slot.count <= 0 then
                self.items[self.selected] = nil
            end
            return true, "item used"
        else
            return false, tostring(err or "use failed")
        end
    end
    
    return false, "item has no use function"
end

--- Serializes the inventory for save/load
--- @return table Serialized inventory data
function Inventory:serialize()
    local data = {
        slots = self.slots,
        selected = self.selected,
        items = {}
    }
    
    for i = 1, self.slots do
        local slot = self.items[i]
        if slot then
            data.items[i] = {
                proto_name = slot.proto.name or "unknown",
                count = slot.count,
                data = slot.data
            }
        end
    end
    
    return data
end

return Inventory
