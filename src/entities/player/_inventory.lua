-- local Love = require "core.love"
-- local Object = require "core.object"
-- local Control = require "src.entities.control"
-- local Physics = require "src.world.physics"
-- local Inventory = require "src.entities.inventory"
local Stack = require "src.entities.stack"
-- local Weapon = require "src.entities.weapon"
-- local Jetpack = require "src.entities.jetpack"
-- local Vector = require "src.game.vector"
-- local Omnitool = require "src.entities.omnitool"
-- local Stance = require "src.entities.stance"
-- local Health = require "src.entities.health"
-- local Armor = require "src.entities.armor"
-- local Stamina = require "src.entities.stamina"
-- local Registry = require "src.registries"
-- local ITEMS = Registry.items()

function Player.keypressed(self, key)
    if key == "tab" then
        self.inventory_open = not self.inventory_open
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
