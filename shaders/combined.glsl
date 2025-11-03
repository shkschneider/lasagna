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
    
    // === PLAYER LIGHT ===
    // Calculate distance from current pixel to player position
    float dist = distance(screen_coords, player_pos);
    
    // Calculate player light intensity (1.0 at player, 0.0 at player_radius)
    float player_intensity = 1.0 - smoothstep(0.0, player_radius, dist);
    
    // Reduce player light through solid blocks
    // Sample points along the line from player to current position
    vec2 to_pixel = screen_coords - player_pos;
    float occlusion = 0.0;
    int samples = 8;  // Number of occlusion samples
    
    for (int i = 1; i <= samples; i++) {
        float t = float(i) / float(samples);
        vec2 sample_pos = player_pos + to_pixel * t;
        vec2 sample_uv = sample_pos / love_ScreenSize.xy;
        
        // Check if sample position is within bounds
        if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
            vec4 sample_surface = Texel(surface_map, sample_uv);
            occlusion += sample_surface.r * 0.3;  // Each solid block reduces light by 30%
        }
    }
    
    // Apply occlusion to player light
    player_intensity = player_intensity * (1.0 - clamp(occlusion, 0.0, 0.95));
    
    // Add warm tint to the player's light
    vec3 player_light_color = vec3(1.0, 0.95, 0.8);  // Warm white/yellow
    float player_light = player_intensity * 0.85;  // Player light contribution
    
    // === SUN LIGHT ===
    // Calculate vertical gradient (top = bright, bottom = darker)
    float vertical_pos = screen_coords.y / love_ScreenSize.y;
    
    // Sun light comes from above - stronger at the top
    float vertical_falloff = 1.0 - (vertical_pos * 0.4);  // 40% falloff from top to bottom
    
    // Calculate sun light intensity with vertical gradient
    float sun_light = sun_intensity * vertical_falloff;
    
    // Reduce sun light through solid blocks (from above)
    float sun_occlusion = 0.0;
    int sun_samples = 6;
    
    for (int i = 1; i <= sun_samples; i++) {
        float step = float(i) * 16.0;  // Sample every 16 pixels upward
        vec2 sun_sample_pos = vec2(screen_coords.x, screen_coords.y - step);
        vec2 sun_sample_uv = sun_sample_pos / love_ScreenSize.xy;
        
        if (sun_sample_uv.y >= 0.0 && sun_sample_uv.y <= 1.0) {
            vec4 sun_sample_surface = Texel(surface_map, sun_sample_uv);
            sun_occlusion += sun_sample_surface.r * 0.25;  // Each block reduces sun by 25%
        }
    }
    
    sun_light = sun_light * (1.0 - clamp(sun_occlusion, 0.0, 0.95));
    
    // Add subtle directional glow based on sun angle
    float horizontal_pos = screen_coords.x / love_ScreenSize.x;
    float angle_effect = sin(sun_angle) * (horizontal_pos - 0.5) * 0.15;
    sun_light = clamp(sun_light + angle_effect, 0.0, 1.0);
    
    // Add warm tint during sunrise/sunset (when intensity is mid-range)
    float sunrise_sunset_factor = 4.0 * sun_intensity * (1.0 - sun_intensity);  // Peaks at 0.5
    vec3 sun_light_color = mix(vec3(1.0), vec3(1.0, 0.85, 0.7), sunrise_sunset_factor);
    
    // === COMBINE LIGHTS ===
    // Use additive blending for multiple light sources
    float total_light = clamp(sun_light + player_light, 0.0, 1.0);
    
    // Ensure solid blocks have minimum light visibility
    if (is_solid > 0.5) {
        total_light = max(total_light, 0.05);  // Minimum light for visibility
    }
    
    // Apply lighting to the pixel
    vec3 lit_color = pixel.rgb * total_light;
    
    // Apply color tints
    lit_color = mix(lit_color, lit_color * player_light_color, player_intensity * 0.3);
    lit_color = mix(lit_color, lit_color * sun_light_color, sunrise_sunset_factor * 0.2);
    
    return vec4(lit_color, pixel.a) * color;
}
