local shaders = {}

shaders.whiteout = love.graphics.newShader[[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);

        if (screen_coords.x < 400.0) {
            return vec4(0, 0, 1, pixel.a);
        }

        return pixel * color;
    }
]]

shaders.greyscale = love.graphics.newShader[[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);

        // Calculate average of RGB channels
        float grey = (pixel.r + pixel.g + pixel.b) / 3.0;

        return vec4(grey, grey, grey, pixel.a) * color;
    }
]]

shaders.sepia = love.graphics.newShader[[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);

        // Apply sepia tone transformation matrix
        // These values create the warm, brownish vintage photo effect
        float r = (pixel.r * 0.393) + (pixel.g * 0.769) + (pixel.b * 0.189);
        float g = (pixel.r * 0.349) + (pixel.g * 0.686) + (pixel.b * 0.168);
        float b = (pixel.r * 0.272) + (pixel.g * 0.534) + (pixel.b * 0.131);

        // Clamp values to prevent overflow
        r = min(r, 1.0);
        g = min(g, 1.0);
        b = min(b, 1.0);

        return vec4(r, g, b, pixel.a) * color;
    }
]]

shaders.light = love.graphics.newShader[[
    extern vec2 playerPosition;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);

        float distance = length(screen_coords - playerPosition);
        float fade = clamp(distance / 250, 0.0, 1.0);

        pixel.a = pixel.a * fade;

        return pixel * color;
    }
]]

return shaders
