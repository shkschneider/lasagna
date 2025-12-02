-- Save
-- Handles saving and loading game state to/from .sav files
-- Uses serializer for binary serialization
--
-- Save file format (binary serialized via serializer):
-- {
--     version = {major, minor, patch},  -- Game version for compatibility
--     seed = number,                     -- World seed for terrain regeneration
--     changes = {                        -- Block modifications from generated terrain
--         [-1] = {[col] = {[row] = block_id, ...}, ...},
--         [0] = {...},
--         [1] = {...},
--     },
--     player = {                         -- Player state
--         position = {x, y, z},
--         velocity = {x, y},
--         health = {current, max},
--         stamina = {current, max},
--         omnitool = {tier},
--         hotbar = {...},                -- Inventory slots
--         backpack = {...},              -- Inventory slots
--     },
-- }

local serializer = require "libraries.bakpakin.binser"

local Object = require "core.object"
local Stack = require "src.data.stack"

local Save = Object {
    id = "save",
    priority = 200,  -- Low priority, runs after game logic
    SAVE_DIR = "",  -- Prefix for save path (love.filesystem uses save directory by default)
    SAVE_FILENAME = "world.sav",
    -- Cache for save info to avoid repeated parsing
    _cached_info = nil,
    _cached_info_modtime = nil,
    -- Autosave settings
    AUTOSAVE_INTERVAL = 60,  -- Autosave every 60 seconds
    _autosave_timer = nil,   -- Timer for autosave (nil until after spawn)
}

-- Helper function to ensure table keys are numbers
-- Binser preserves numeric keys, but this is a safety measure for robust loading
local function ensure_numeric_key(key)
    if type(key) == "string" then
        return tonumber(key)
    end
    return key
end

-- Get the full save file path
function Save.get_save_path(self)
    return self.SAVE_DIR .. self.SAVE_FILENAME
end

-- Update autosave timer
function Save.update(self, dt)
    -- Initialize autosave timer on first update (after spawn)
    if self._autosave_timer == nil then
        self._autosave_timer = self.AUTOSAVE_INTERVAL
        Log.info("Save", "Autosave enabled (every " .. self.AUTOSAVE_INTERVAL .. " seconds)")
    end

    -- Count down timer
    self._autosave_timer = self._autosave_timer - dt

    -- Trigger autosave when timer expires
    if self._autosave_timer <= 0 then
        self:save()
        -- Reset timer for next autosave
        self._autosave_timer = self.AUTOSAVE_INTERVAL
    end
end

-- Serialize inventory storage (hotbar or backpack) to saveable format
local function serialize_storage(storage)
    if not storage then return nil end

    local data = {
        size = storage.size,
        selected_slot = storage.selected_slot,
        slots = {},
    }

    for i = 1, storage.size do
        local slot = storage.slots[i]
        if slot then
            data.slots[i] = {
                item_id = slot.item_id,
                block_id = slot.block_id,
                count = slot.count,
            }
        end
    end

    return data
end

-- Deserialize inventory storage from saved format
local function deserialize_storage(storage, saved_data)
    if not storage or not saved_data then return end

    storage.selected_slot = saved_data.selected_slot or 1

    for i = 1, storage.size do
        local slot_data = saved_data.slots and saved_data.slots[i]
        if slot_data then
            local id_type = slot_data.item_id and "item" or "block"
            local id = slot_data.item_id or slot_data.block_id
            storage.slots[i] = Stack.new(id, slot_data.count, id_type)
        else
            storage.slots[i] = nil
        end
    end
end

-- Create save data structure from current game state
function Save.create_save_data(self)
    local save_data = {
        -- Game version for compatibility checking
        version = {
            major = G.VERSION.major,
            minor = G.VERSION.minor,
            patch = G.VERSION.patch,
        },
        -- World seed for terrain regeneration
        seed = G.world.generator.data.seed,
        -- Block changes from generated terrain
        changes = {},
        -- Player state
        player = nil,
    }

    -- Copy block changes (only non-nil values)
    local world_changes = G.world.generator.data.changes
    for z = LAYER_MIN, LAYER_MAX do
        if world_changes[z] then
            save_data.changes[z] = {}
            for col, rows in pairs(world_changes[z]) do
                if next(rows) then  -- Only include non-empty columns
                    save_data.changes[z][col] = {}
                    for row, block_id in pairs(rows) do
                        save_data.changes[z][col][row] = block_id
                    end
                end
            end
        end
    end

    -- Save player state
    if G.player then
        save_data.player = {
            position = {
                x = G.player.position.x,
                y = G.player.position.y,
                z = G.player.position.z,
            },
            velocity = {
                x = G.player.velocity.x,
                y = G.player.velocity.y,
            },
            health = {
                current = G.player.health.current,
                max = G.player.health.max,
            },
            stamina = {
                current = G.player.stamina.current,
                max = G.player.stamina.max,
            },
            omnitool = {
                tier = G.player.omnitool.tier,
            },
            hotbar = serialize_storage(G.player.hotbar),
            backpack = serialize_storage(G.player.backpack),
        }
    end

    return save_data
end

-- Apply loaded save data to current game state
function Save.apply_save_data(self, save_data)
    if not save_data then
        Log.error("Save", "No save data to apply")
        return false
    end

    -- Version compatibility check (warn but don't fail)
    if save_data.version then
        local current = G.VERSION
        local saved = save_data.version
        if saved.major ~= current.major or saved.minor ~= current.minor then
            Log.warning("Save", string.format(
                "Save version mismatch: saved %d.%d.%s, current %s",
                saved.major, saved.minor, tostring(saved.patch or "x"),
                current:tostring()
            ))
        end
    end

    -- Apply block changes to world
    if save_data.changes then
        local world_changes = G.world.generator.data.changes
        local world_columns = G.world.generator.data.columns

        for z, cols in pairs(save_data.changes) do
            z = ensure_numeric_key(z)
            if z then
                if not world_changes[z] then world_changes[z] = {} end
                if not world_columns[z] then world_columns[z] = {} end

                for col, rows in pairs(cols) do
                    col = ensure_numeric_key(col)
                    if col then
                        if not world_changes[z][col] then world_changes[z][col] = {} end
                        if not world_columns[z][col] then world_columns[z][col] = {} end

                        for row, block_id in pairs(rows) do
                            row = ensure_numeric_key(row)
                            if row then
                                world_changes[z][col][row] = block_id
                                world_columns[z][col][row] = block_id
                            end
                        end
                    end
                end
            end
        end
    end

    -- Apply player state
    if save_data.player and G.player then
        local player_data = save_data.player

        -- Position
        if player_data.position then
            G.player.position.x = player_data.position.x
            G.player.position.y = player_data.position.y
            G.player.position.z = player_data.position.z
        end

        -- Velocity
        if player_data.velocity then
            G.player.velocity.x = player_data.velocity.x
            G.player.velocity.y = player_data.velocity.y
        end

        -- Health
        if player_data.health then
            G.player.health.current = player_data.health.current
            G.player.health.max = player_data.health.max
        end

        -- Stamina
        if player_data.stamina then
            G.player.stamina.current = player_data.stamina.current
            G.player.stamina.max = player_data.stamina.max
        end

        -- Omnitool
        if player_data.omnitool then
            G.player.omnitool.tier = player_data.omnitool.tier
        end

        -- Inventory
        if player_data.hotbar then
            deserialize_storage(G.player.hotbar, player_data.hotbar)
        end
        if player_data.backpack then
            deserialize_storage(G.player.backpack, player_data.backpack)
        end
    end

    Log.info("Save", "Save data applied successfully")
    return true
end

-- Save game state to file
function Save.save(self)
    local save_data = self:create_save_data()
    local serialized = serializer.serialize(save_data)

    local path = self:get_save_path()
    local success, message = love.filesystem.write(path, serialized)

    if success then
        Log.info("Save", "Game saved to " .. path)
        -- Invalidate cache when save file changes
        self._cached_info = nil
        self._cached_info_modtime = nil
        return true
    else
        Log.error("Save", "Failed to save: " .. tostring(message))
        return false
    end
end

-- Load game state from file
function Save.load(self)
    local path = self:get_save_path()

    -- Check if save file exists
    if not love.filesystem.getInfo(path) then
        Log.verbose("No save file found at " .. path)
        return nil
    end

    -- Read save file
    local content, message = love.filesystem.read(path)
    if not content then
        Log.error("Failed to read save: " .. tostring(message))
        return nil
    end

    -- Deserialize save data
    local success, results = pcall(serializer.deserialize, content)
    if not success then
        Log.error("Failed to deserialize save: " .. tostring(results))
        return nil
    end

    local save_data = results[1]
    if not save_data then
        Log.error("Save file is empty or invalid")
        return nil
    end

    Log.info("Save", "Save loaded from " .. path)
    return save_data
end

-- Check if a save file exists
function Save.exists(self)
    local path = self:get_save_path()
    return love.filesystem.getInfo(path) ~= nil
end

-- Delete save file
function Save.delete(self)
    local path = self:get_save_path()
    if love.filesystem.getInfo(path) then
        local success = love.filesystem.remove(path)
        if success then
            Log.info("Save file deleted: " .. path)
            -- Clear cache when save is deleted
            self._cached_info = nil
            self._cached_info_modtime = nil
        else
            Log.error("Failed to delete save file: " .. path)
        end
        return success
    end
    return true  -- No file to delete
end

-- Get save file info (for displaying save info)
-- Uses caching to avoid repeated parsing of the save file
function Save.get_info(self)
    local path = self:get_save_path()
    local info = love.filesystem.getInfo(path)
    if not info then
        self._cached_info = nil
        self._cached_info_modtime = nil
        return nil
    end

    -- Check if we have a valid cached result
    if self._cached_info and self._cached_info_modtime == info.modtime then
        return self._cached_info
    end

    -- Load and parse the save file (needed for version/seed info)
    local save_data = self:load()
    local result
    if not save_data then
        result = {
            path = path,
            size = info.size,
            modtime = info.modtime,
        }
    else
        result = {
            path = path,
            size = info.size,
            modtime = info.modtime,
            version = save_data.version,
            seed = save_data.seed,
        }
    end

    -- Cache the result
    self._cached_info = result
    self._cached_info_modtime = info.modtime

    return result
end

return Save
