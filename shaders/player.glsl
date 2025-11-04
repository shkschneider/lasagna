// Player lighting shader for Lasagna
// 2D raycasting with shadows

uniform vec2 player_pos;       // Player position in world coordinates
uniform float player_radius;   // Maximum radius for light rays
uniform Image surface_map;     // Texture containing solid block positions (in screen space)
uniform float camera_x;        // Camera X position for coordinate conversion

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);
    
    // screen_coords are in world space due to translate(-cx, 0)
    // Calculate distance from current pixel to player position (both in world space)
    float dist = distance(screen_coords, player_pos);
    
    // If outside light radius, return dark
    if (dist > player_radius) {
        return vec4(pixel.rgb * 0.05, pixel.a) * color;  // 5% ambient
    }
    
    // Distance-based light falloff (quadratic for natural look)
    float attenuation = 1.0 - smoothstep(0.0, player_radius, dist);
    attenuation = attenuation * attenuation;  // Quadratic falloff
    
    // Raycast from player to current pixel to check for occlusion
    vec2 direction = screen_coords - player_pos;
    float ray_length = length(direction);
    
    if (ray_length < 1.0) {
        // Very close to player, always fully lit
        vec3 lit_color = pixel.rgb * attenuation;
        return vec4(lit_color, pixel.a) * color;
    }
    
    vec2 ray_dir = normalize(direction);
    
    // Sample along the ray to check for blocking surfaces
    int samples = 20;
    bool is_blocked = false;
    
    // Sample from 0 to just before reaching the target pixel
    for (int i = 0; i < samples; i++) {
        // Sample at positions between player and pixel (not including the pixel itself)
        float t = (float(i) / float(samples)) * ray_length * 0.95;  // 95% to avoid self-occlusion
        vec2 sample_world_pos = player_pos + ray_dir * t;
        
        // Convert world position to screen position for surface map lookup
        vec2 sample_screen_pos = sample_world_pos - vec2(camera_x, 0.0);
        vec2 sample_uv = sample_screen_pos / love_ScreenSize.xy;
        
        // Check if sample position is within bounds
        if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && 
            sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
            vec4 sample_surface = Texel(surface_map, sample_uv);
            
            // If we hit a solid block before reaching the pixel, it's in shadow
            if (sample_surface.r > 0.5) {
                is_blocked = true;
                break;
            }
        }
    }
    
    // Calculate final light intensity
    float final_intensity;
    if (is_blocked) {
        // In shadow - very dark (5% ambient)
        final_intensity = 0.05;
    } else {
        // Direct light - apply distance attenuation
        final_intensity = attenuation;
    }
    
    // Apply lighting to the pixel
    vec3 lit_color = pixel.rgb * final_intensity;
    
    return vec4(lit_color, pixel.a) * color;
}
