local Object = require("lib.object")
local log = require("lib.log")

local Lighting = Object {}

function Lighting:new()
    -- Light sources: list of {x, y, z, intensity, radius}
    self.light_sources = {}
    -- Ambient light level (0.0 to 1.0)
    self.ambient_light = 1.0
    -- Shader for rendering lighting
    self.shader = nil
    self.occlusion_canvas = nil
    self.lighting_canvas = nil
end

function Lighting:load_shader()
    -- Load the lighting shader
    local shader_path = "shaders/lighting.glsl"
    local success, result = pcall(function()
        return love.graphics.newShader(shader_path)
    end)
    
    if success then
        self.shader = result
        log.info("Lighting shader loaded successfully")
    else
        log.warn("Failed to load lighting shader: " .. tostring(result))
        self.shader = nil
    end
end

function Lighting:create_canvases(width, height)
    -- Create canvas for occlusion map (which blocks are solid)
    self.occlusion_canvas = love.graphics.newCanvas(width, height)
    self.occlusion_canvas:setFilter("nearest", "nearest")
    
    -- Create canvas for lighting overlay
    self.lighting_canvas = love.graphics.newCanvas(width, height)
    self.lighting_canvas:setFilter("linear", "linear")
    
    log.info(string.format("Created lighting canvases: %dx%d", width, height))
end

-- Add a light source
-- @param x: world x position (in blocks)
-- @param y: world y position (in blocks)
-- @param z: layer
-- @param intensity: brightness (0.0 to 1.0)
-- @param radius: how far the light reaches (in blocks)
function Lighting:add_light(x, y, z, intensity, radius)
    table.insert(self.light_sources, {
        x = x,
        y = y,
        z = z,
        intensity = intensity or 1.0,
        radius = radius or 10,
    })
end

-- Remove all light sources
function Lighting:clear_lights()
    self.light_sources = {}
end

-- Set ambient light level based on time of day
-- @param level: 0.0 (complete darkness) to 1.0 (full brightness)
function Lighting:set_ambient_light(level)
    self.ambient_light = math.max(0.0, math.min(1.0, level))
end

-- Calculate light level at a specific position
-- @param x: world x position (in blocks)
-- @param y: world y position (in blocks)
-- @param z: layer
-- @return light level (0.0 to 1.0)
function Lighting:get_light_level(x, y, z)
    local max_light = self.ambient_light
    
    -- Check all light sources
    for _, light in ipairs(self.light_sources) do
        -- Only consider lights on the same layer
        if light.z == z then
            local dx = x - light.x
            local dy = y - light.y
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < light.radius then
                -- Quadratic falloff: light decreases with square of distance
                local falloff = (1.0 - (distance / light.radius)) ^ 2
                local light_contribution = light.intensity * falloff
                
                -- Take the maximum light level from any source
                max_light = math.max(max_light, light_contribution)
            end
        end
    end
    
    return math.max(0.0, math.min(1.0, max_light))
end

-- Update lighting system (called each frame)
function Lighting:update(dt)
    -- Future: could add dynamic lights, flickering, etc.
end

-- Generate occlusion map for the current view
-- This creates a texture where white = solid block, black = empty space
function Lighting:generate_occlusion_map(world, camera_x, screen_width, screen_height, player_z)
    if not self.occlusion_canvas then
        return
    end
    
    love.graphics.setCanvas(self.occlusion_canvas)
    love.graphics.clear(0, 0, 0, 1)  -- Start with black (no occlusion)
    
    -- Draw white pixels where solid blocks exist
    love.graphics.setColor(1, 1, 1, 1)
    
    local left_col = math.floor(camera_x / C.BLOCK_SIZE)
    local right_col = math.ceil((camera_x + screen_width) / C.BLOCK_SIZE) + 1
    
    local layer = world.layers and world.layers[player_z]
    if layer then
        for col = left_col, right_col do
            local column = layer.tiles[col]
            if column then
                for row = 1, C.WORLD_HEIGHT do
                    if world:is_solid(player_z, col, row) then
                        local px = (col - 1) * C.BLOCK_SIZE - camera_x
                        local py = (row - 1) * C.BLOCK_SIZE
                        love.graphics.rectangle("fill", px, py, C.BLOCK_SIZE, C.BLOCK_SIZE)
                    end
                end
            end
        end
    end
    
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
end

-- Render the lighting overlay using the shader
function Lighting:render_lighting_overlay(screen_width, screen_height, camera_x)
    if not self.shader or not self.lighting_canvas then
        return
    end
    
    -- Prepare shader uniforms
    self.shader:send("screen_size", {screen_width, screen_height})
    self.shader:send("ambient_light", self.ambient_light)
    
    -- Convert light sources to screen coordinates and send to shader
    local num_lights = math.min(#self.light_sources, 32)
    self.shader:send("num_lights", num_lights)
    
    if num_lights > 0 then
        local positions = {}
        local intensities = {}
        
        for i = 1, num_lights do
            local light = self.light_sources[i]
            -- Convert world coordinates to screen coordinates
            local screen_x = (light.x - 1) * C.BLOCK_SIZE - camera_x
            local screen_y = (light.y - 1) * C.BLOCK_SIZE
            local radius_pixels = light.radius * C.BLOCK_SIZE
            
            positions[i] = {screen_x, screen_y, radius_pixels}
            intensities[i] = light.intensity
        end
        
        self.shader:send("light_positions", unpack(positions))
        self.shader:send("light_intensities", unpack(intensities))
    end
    
    -- Send occlusion map
    if self.occlusion_canvas then
        self.shader:send("light_occlusion_map", self.occlusion_canvas)
    end
    
    -- Render lighting to canvas
    love.graphics.setCanvas(self.lighting_canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    love.graphics.setShader(self.shader)
    love.graphics.rectangle("fill", 0, 0, screen_width, screen_height)
    love.graphics.setShader()
    
    love.graphics.setCanvas()
end

-- Draw the lighting overlay on top of the world
function Lighting:draw()
    if self.lighting_canvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setBlendMode("multiply", "premultiplied")
        love.graphics.draw(self.lighting_canvas, 0, 0)
        love.graphics.setBlendMode("alpha")
    end
end

return Lighting
