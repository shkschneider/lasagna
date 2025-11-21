-- Camera system with smooth follow

local camera = {}

function camera.new(x, y)
    return {
        x = x or 0,
        y = y or 0,
        target_x = x or 0,
        target_y = y or 0,
        smoothness = 5, -- Lower = smoother
    }
end

function camera.follow(cam, target_x, target_y, dt)
    cam.target_x = target_x
    cam.target_y = target_y
    
    -- Smooth interpolation
    local dx = cam.target_x - cam.x
    local dy = cam.target_y - cam.y
    
    cam.x = cam.x + dx * cam.smoothness * dt
    cam.y = cam.y + dy * cam.smoothness * dt
end

function camera.get_offset(cam, screen_width, screen_height)
    return cam.x - screen_width / 2, cam.y - screen_height / 2
end

return camera
