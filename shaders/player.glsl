// Player lighting shader for Lasagna
// Raycasts light rays in all directions from player, lights surfaces without distance falloff

uniform vec2 player_pos;       // Player position in screen coordinates
uniform float player_radius;   // Maximum radius for light rays
uniform Image surface_map;     // Texture containing solid block positions

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);
    
    // Calculate distance from current pixel to player position
    float dist = distance(screen_coords, player_pos);
    
    // Don't light pixels beyond the light radius
    if (dist > player_radius) {
        return vec4(pixel.rgb * 0.0, pixel.a) * color;  // Pitch black beyond radius
    }
    
    // Raycast from player to current pixel to check if light reaches it
    vec2 direction = screen_coords - player_pos;
    float ray_length = length(direction);
    vec2 ray_dir = normalize(direction);
    
    // Sample along the ray to check for blocking surfaces
    int samples = 16;  // More samples for accurate ray detection
    float step_size = ray_length / float(samples);
    bool is_blocked = false;
    
    for (int i = 1; i < samples; i++) {
        float t = float(i) * step_size;
        vec2 sample_pos = player_pos + ray_dir * t;
        vec2 sample_uv = sample_pos / love_ScreenSize.xy;
        
        // Check if sample position is within bounds
        if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
            vec4 sample_surface = Texel(surface_map, sample_uv);
            // If we hit a solid block, light is blocked
            if (sample_surface.r > 0.5) {
                is_blocked = true;
                break;
            }
        }
    }
    
    // Light intensity: full brightness if not blocked, pitch black if blocked
    float light_intensity = is_blocked ? 0.0 : 1.0;
    
    // Apply lighting to the pixel (no distance falloff, no tint)
    vec3 lit_color = pixel.rgb * light_intensity;
    
    return vec4(lit_color, pixel.a) * color;
}
