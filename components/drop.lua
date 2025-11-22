-- Drop component
-- Drop entity data

local Drop = {}

function Drop.new(block_id, count, lifetime, pickup_delay)
    return {
        block_id = block_id,
        count = count or 1,
        lifetime = lifetime or 300,
        pickup_delay = pickup_delay or 0.5,
    }
end

return Drop
