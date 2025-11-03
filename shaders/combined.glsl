// Combined lighting shader for Lasagna
// Handles both player light and sun light with occlusion from solid blocks

uniform vec2 player_pos;       // Player position in screen coordinates
uniform float player_radius;   // Radius of the player's light effect
uniform float sun_intensity;   // Sun brightness (0.0 = night, 1.0 = full day)
uniform float sun_angle;       // Sun angle in radians (affects direction)
uniform Image surface_map;     // Texture containing solid block positions

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);
    
    // Sample surface map to check if current pixel is a solid block
    vec2 surface_uv = screen_coords / love_ScreenSize.xy;
    vec4 surface_sample = Texel(surface_map, surface_uv);
    float is_solid = surface_sample.r;  // 1.0 = solid block, 0.0 = air
    
    // === PLAYER LIGHT (GLOW) ===
    // Calculate distance from current pixel to player position
    float dist = distance(screen_coords, player_pos);
    
    // Calculate player light intensity with stronger glow near player
    float player_intensity = 1.0 - smoothstep(0.0, player_radius, dist);
    
    // Add a bright inner glow around the player (bloom effect)
    float inner_glow = 1.0 - smoothstep(0.0, player_radius * 0.3, dist);
    inner_glow = pow(inner_glow, 2.0);  // Sharper falloff for glow
    
    // Reduce player light through solid blocks (less aggressive)
    vec2 to_pixel = screen_coords - player_pos;
    float occlusion = 0.0;
    int samples = 6;  // Fewer samples for better performance
    
    for (int i = 1; i <= samples; i++) {
        float t = float(i) / float(samples);
        vec2 sample_pos = player_pos + to_pixel * t;
        vec2 sample_uv = sample_pos / love_ScreenSize.xy;
        
        if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
            vec4 sample_surface = Texel(surface_map, sample_uv);
            occlusion += sample_surface.r * 0.15;  // Less aggressive: 15% reduction per block
        }
    }
    
    // Apply occlusion to player light but keep glow strong
    player_intensity = player_intensity * (1.0 - clamp(occlusion, 0.0, 0.85));
    float glow_intensity = inner_glow * 1.5;  // Bright glow not affected by occlusion
    
    // Combine player light with glow
    vec3 player_light_color = vec3(1.0, 0.9, 0.7);  // Warm golden
    float player_light = (player_intensity + glow_intensity) * 1.2;  // Brighter overall
    
    // === SUN LIGHT (AMBIENT) ===
    // Base sun light - stronger ambient on surface
    float base_sun = sun_intensity * 0.9;  // Strong base lighting
    
    // Vertical gradient - less aggressive
    float vertical_pos = screen_coords.y / love_ScreenSize.y;
    float vertical_falloff = 1.0 - (vertical_pos * 0.2);  // Only 20% falloff
    
    float sun_light = base_sun * vertical_falloff;
    
    // Reduce sun light through solid blocks (less aggressive for surface)
    float sun_occlusion = 0.0;
    int sun_samples = 4;  // Fewer samples
    
    for (int i = 1; i <= sun_samples; i++) {
        float step = float(i) * 20.0;  // Sample every 20 pixels upward
        vec2 sun_sample_pos = vec2(screen_coords.x, screen_coords.y - step);
        vec2 sun_sample_uv = sun_sample_pos / love_ScreenSize.xy;
        
        if (sun_sample_uv.y >= 0.0 && sun_sample_uv.y <= 1.0) {
            vec4 sun_sample_surface = Texel(surface_map, sun_sample_uv);
            sun_occlusion += sun_sample_surface.r * 0.12;  // Less aggressive: 12% reduction
        }
    }
    
    sun_light = sun_light * (1.0 - clamp(sun_occlusion, 0.0, 0.75));
    
    // Add subtle directional glow based on sun angle
    float horizontal_pos = screen_coords.x / love_ScreenSize.x;
    float angle_effect = sin(sun_angle) * (horizontal_pos - 0.5) * 0.1;
    sun_light = clamp(sun_light + angle_effect, 0.0, 1.0);
    
    // Warm tint during sunrise/sunset
    float sunrise_sunset_factor = 4.0 * sun_intensity * (1.0 - sun_intensity);
    vec3 sun_light_color = mix(vec3(1.0), vec3(1.0, 0.8, 0.6), sunrise_sunset_factor);
    
    // === COMBINE LIGHTS ===
    // Strong ambient base to prevent too-dark areas
    float ambient_base = max(sun_intensity * 0.3, 0.2);  // Minimum 20% ambient
    
    // Additive blending with higher minimum
    float total_light = clamp(sun_light + player_light + ambient_base, 0.0, 1.5);
    
    // Apply lighting to the pixel
    vec3 lit_color = pixel.rgb * total_light;
    
    // Apply color tints (more visible)
    lit_color = mix(lit_color, lit_color * player_light_color, min(player_light * 0.4, 1.0));
    lit_color = mix(lit_color, lit_color * sun_light_color, sunrise_sunset_factor * 0.3);
    
    return vec4(lit_color, pixel.a) * color;
}
