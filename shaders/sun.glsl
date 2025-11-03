// Sun lighting shader for Lasagna
// Creates directional light from above, proportionate to time of day

uniform float sun_intensity;   // Sun brightness (0.0 = night, 1.0 = full day)
uniform float sun_angle;        // Sun angle in radians (affects direction)

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);
    
    // Calculate vertical gradient (top = bright, bottom = darker)
    // Normalize screen_coords.y to 0.0 (top) to 1.0 (bottom)
    float vertical_pos = screen_coords.y / love_ScreenSize.y;
    
    // Sun light comes from above - stronger at the top
    // Add a gradient falloff as we go down
    float vertical_falloff = 1.0 - (vertical_pos * 0.4);  // 40% falloff from top to bottom
    
    // Calculate sun light intensity with vertical gradient
    float sun_light = sun_intensity * vertical_falloff;
    
    // Add a subtle directional glow based on sun angle
    // This creates a slight left-to-right variation during sunrise/sunset
    float horizontal_pos = screen_coords.x / love_ScreenSize.x;
    float angle_effect = sin(sun_angle) * (horizontal_pos - 0.5) * 0.15;  // Subtle 15% variation
    sun_light = clamp(sun_light + angle_effect, 0.0, 1.0);
    
    // Apply sun lighting to the pixel
    vec3 lit_color = pixel.rgb * sun_light;
    
    // Add warm tint during sunrise/sunset (when intensity is mid-range)
    float sunrise_sunset_factor = 4.0 * sun_intensity * (1.0 - sun_intensity);  // Peaks at 0.5
    vec3 warm_tint = vec3(1.0, 0.85, 0.7);  // Warm orange/yellow
    lit_color = mix(lit_color, lit_color * warm_tint, sunrise_sunset_factor * 0.3);
    
    return vec4(lit_color, pixel.a) * color;
}
