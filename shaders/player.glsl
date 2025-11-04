// Player lighting shader for Lasagna
// 2D raycasting with soft shadows (Godot-style)

uniform vec2 player_pos;       // Player position in screen coordinates
uniform float player_radius;   // Maximum radius for light rays
uniform Image surface_map;     // Texture containing solid block positions

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);
    
    // Calculate distance from current pixel to player position
    float dist = distance(screen_coords, player_pos);
    
    // Distance-based light falloff (quadratic for natural look)
    float attenuation = 1.0 - smoothstep(0.0, player_radius, dist);
    attenuation = attenuation * attenuation;  // Quadratic falloff
    
    // Raycast from player to current pixel to check for occlusion
    vec2 direction = screen_coords - player_pos;
    float ray_length = length(direction);
    
    if (ray_length < 1.0) {
        // Very close to player, always lit
        vec3 lit_color = pixel.rgb * attenuation;
        return vec4(lit_color, pixel.a) * color;
    }
    
    vec2 ray_dir = normalize(direction);
    
    // Sample along the ray to check for blocking surfaces
    int samples = 12;
    float occlusion = 0.0;
    
    for (int i = 1; i < samples; i++) {
        float t = (float(i) / float(samples)) * ray_length;
        vec2 sample_pos = player_pos + ray_dir * t;
        vec2 sample_uv = sample_pos / love_ScreenSize.xy;
        
        // Check if sample position is within bounds
        if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && 
            sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
            vec4 sample_surface = Texel(surface_map, sample_uv);
            
            // Accumulate occlusion with distance-based weight for soft shadows
            if (sample_surface.r > 0.5) {
                float distance_factor = t / ray_length;
                occlusion += (1.0 - distance_factor) * 0.25;
            }
        }
    }
    
    // Soft shadow: occlusion reduces light but not completely to 0
    occlusion = clamp(occlusion, 0.0, 0.95);
    float shadow = 1.0 - occlusion;
    
    // Combine attenuation with shadow
    float final_intensity = attenuation * shadow;
    
    // Add small ambient to prevent complete blackness
    final_intensity = max(final_intensity, 0.05);
    
    // Apply lighting to the pixel
    vec3 lit_color = pixel.rgb * final_intensity;
    
    return vec4(lit_color, pixel.a) * color;
}
