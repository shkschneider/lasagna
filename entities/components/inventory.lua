local Object = require("lib.object")

local Inventory = Object {}

function Inventory:new(player, opts)
    assert(player)
    opts = opts or {}
    self.player = player
    self.slots = opts.slots or 9
    self.items = {}  -- Array of { proto, count, data }
    self.selected = 1
    for i = 1, self.slots do
        self.items[i] = nil
    end
end

function Inventory:add(proto, count)
    if not proto or not count or count <= 0 then
        return count or 0
    end
    local max_stack = math.min(proto.max_stack or C.MAX_STACK, C.MAX_STACK)
    local leftover = count
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

function Inventory:use_selected(ctx)
    local slot = self.items[self.selected]
    if not slot then
        return false, "no item selected"
    end
    local proto = slot.proto
    if not proto then
        return false, "invalid item"
    end
    if type(proto.use) == "function" then
        local success, err = pcall(proto.use, self.player, ctx, slot.data)
        if success and err ~= false then
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

return Inventory
