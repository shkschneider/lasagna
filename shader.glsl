// Player lighting shader - Simple 2D raycasting
// Based on: https://icuwanl.wordpress.com/2018/07/05/light-sources-shadows-part-2/

uniform vec2 player_pos_screen;  // Player position in screen space (pixels from top-left)
uniform float light_radius;      // Maximum light radius in pixels
uniform Image surface_map;       // Solid blocks (white = solid, black = empty)

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);
    
    // Calculate distance from pixel to player (both in screen space)
    vec2 to_pixel = screen_coords - player_pos_screen;
    float dist = length(to_pixel);
    
    // Outside light radius? Dark.
    if (dist > light_radius) {
        return vec4(pixel.rgb * 0.05, pixel.a) * color;
    }
    
    // Start with light intensity based on distance (quadratic falloff)
    float norm_dist = dist / light_radius;
    float attenuation = 1.0 - (norm_dist * norm_dist);
    
    // Raycast from player to this pixel to check for occlusion
    bool in_shadow = false;
    
    if (dist > 2.0) {  // Skip raycasting for pixels very close to player
        vec2 ray_dir = to_pixel / dist;  // Normalized direction
        int num_samples = 16;
        
        // Sample along the ray from player toward pixel
        for (int i = 1; i < num_samples; i++) {
            float t = (float(i) / float(num_samples)) * dist;
            vec2 sample_pos = player_pos_screen + ray_dir * t;
            
            // Convert to UV coordinates for texture sampling
            vec2 uv = sample_pos / love_ScreenSize.xy;
            
            // Check bounds
            if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
                // Sample the surface map
                vec4 surface_pixel = Texel(surface_map, uv);
                
                // If we hit a solid block (white in surface map), this pixel is in shadow
                if (surface_pixel.r > 0.5) {
                    in_shadow = true;
                    break;
                }
            }
        }
    }
    
    // Calculate final light
    float light;
    if (in_shadow) {
        light = 0.05;  // Ambient only
    } else {
        light = attenuation;  // Full light with distance falloff
    }
    
    return vec4(pixel.rgb * light, pixel.a) * color;
}
