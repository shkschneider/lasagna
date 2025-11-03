// Player lighting shader for Lasagna
// Raycasts light outward from player, blocked by solid blocks (Sandustry-style)

uniform vec2 player_pos;       // Player position in screen coordinates
uniform float player_radius;   // Radius of the player's light effect
uniform Image surface_map;     // Texture containing solid block positions

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);
    
    // === PLAYER LIGHT WITH RAYCASTING ===
    // Calculate distance from current pixel to player position
    float dist = distance(screen_coords, player_pos);
    
    // Calculate base light intensity (1.0 at player, 0.0 at player_radius)
    float base_intensity = 1.0 - smoothstep(0.0, player_radius, dist);
    
    // Add a bright inner glow around the player (bloom effect)
    float inner_glow = 1.0 - smoothstep(0.0, player_radius * 0.3, dist);
    inner_glow = pow(inner_glow, 2.0);  // Sharper falloff for glow
    
    // Raycast from player to current pixel to check for solid blocks
    vec2 to_pixel = screen_coords - player_pos;
    float occlusion = 0.0;
    int samples = 8;  // Number of raycast samples
    
    for (int i = 1; i <= samples; i++) {
        float t = float(i) / float(samples);
        vec2 sample_pos = player_pos + to_pixel * t;
        vec2 sample_uv = sample_pos / love_ScreenSize.xy;
        
        // Check if sample position is within bounds
        if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
            vec4 sample_surface = Texel(surface_map, sample_uv);
            // Each solid block reduces light
            occlusion += sample_surface.r * 0.2;
        }
    }
    
    // Apply occlusion to player light
    float player_intensity = base_intensity * (1.0 - clamp(occlusion, 0.0, 0.9));
    
    // Bright glow near player (not affected by occlusion for visible core)
    float glow_intensity = inner_glow * 1.5;
    
    // Combine base light with glow
    float total_light = player_intensity + glow_intensity;
    
    // Add warm golden tint to the player's light
    vec3 player_light_color = vec3(1.0, 0.9, 0.7);  // Warm golden
    
    // Apply lighting to the pixel
    vec3 lit_color = pixel.rgb * total_light;
    
    // Apply warm color tint
    lit_color = mix(lit_color, lit_color * player_light_color, min(total_light * 0.4, 1.0));
    
    return vec4(lit_color, pixel.a) * color;
}
