// Combined lighting shader for Lasagna
// Handles both player light and sun light

uniform vec2 player_pos;       // Player position in screen coordinates
uniform float player_radius;   // Radius of the player's light effect
uniform float sun_intensity;   // Sun brightness (0.0 = night, 1.0 = full day)
uniform float sun_angle;       // Sun angle in radians (affects direction)

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);
    
    // === PLAYER LIGHT ===
    // Calculate distance from current pixel to player position
    float dist = distance(screen_coords, player_pos);
    
    // Calculate player light intensity (1.0 at player, 0.0 at player_radius)
    float player_intensity = 1.0 - smoothstep(0.0, player_radius, dist);
    
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
    
    // Apply lighting to the pixel
    vec3 lit_color = pixel.rgb * total_light;
    
    // Apply color tints
    lit_color = mix(lit_color, lit_color * player_light_color, player_intensity * 0.3);
    lit_color = mix(lit_color, lit_color * sun_light_color, sunrise_sunset_factor * 0.2);
    
    return vec4(lit_color, pixel.a) * color;
}
