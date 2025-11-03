// Simple lighting shader for Lasagna
// Creates a radial light centered on the player

uniform vec2 player_pos;      // Player position in screen coordinates
uniform float light_radius;   // Radius of the light effect
uniform vec3 ambient_color;   // Ambient light color
uniform float ambient_strength; // Ambient light strength

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 pixel = Texel(texture, texture_coords);
    
    // Calculate distance from current pixel to player position
    float dist = distance(screen_coords, player_pos);
    
    // Calculate light intensity (1.0 at player, 0.0 at light_radius)
    float intensity = 1.0 - smoothstep(0.0, light_radius, dist);
    
    // Combine ambient light with player light
    float total_light = ambient_strength + intensity * (1.0 - ambient_strength);
    
    // Apply lighting to the pixel
    vec3 lit_color = pixel.rgb * total_light;
    
    // Optional: Add a slight color tint to the player's light
    lit_color = mix(lit_color, lit_color * vec3(1.0, 0.95, 0.8), intensity * 0.3);
    
    return vec4(lit_color, pixel.a) * color;
}
