// Lighting shader for Lasagna
// Renders darkness overlay with light sources cut out

extern vec2 screen_size;
extern float ambient_light;  // 0.0 to 1.0
extern int num_lights;
extern vec3 light_positions[32];  // x, y, radius (in screen pixels)
extern float light_intensities[32];  // 0.0 to 1.0
extern Image light_occlusion_map;  // 1-bit map where 1 = solid block that blocks light

const int MAX_SAMPLES = 64;  // Ray-casting samples for occlusion

// Check if a ray from light to pixel is blocked by solid blocks
float calculate_occlusion(vec2 light_pos, vec2 pixel_pos) {
    vec2 dir = pixel_pos - light_pos;
    float dist = length(dir);
    
    if (dist < 1.0) return 1.0;  // No occlusion at light center
    
    dir = dir / dist;  // Normalize
    
    // Sample along the ray to check for occlusion
    float sample_count = dist / 4.0;  // Sample every 4 pixels
    int samples = int(min(sample_count, float(MAX_SAMPLES)));
    if (samples < 2) samples = 2;
    
    for (int i = 1; i < samples; i++) {
        float t = float(i) / float(samples);
        vec2 sample_pos = light_pos + dir * (dist * t);
        
        // Convert to UV coordinates for the occlusion map
        vec2 uv = sample_pos / screen_size;
        
        // Check if this position has a solid block
        vec4 occlusion_sample = Texel(light_occlusion_map, uv);
        if (occlusion_sample.r > 0.5) {
            // Block found - calculate how much light is blocked
            float block_distance = dist * t;
            float remaining_distance = dist - block_distance;
            // Light intensity drops off after hitting a block
            return max(0.0, 1.0 - (remaining_distance / 32.0));
        }
    }
    
    return 1.0;  // No occlusion
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Calculate contribution from each light source
    float total_light = 0.0;  // Start with no light, add ambient and sources
    
    for (int i = 0; i < num_lights && i < 32; i++) {
        vec2 light_pos = light_positions[i].xy;
        float light_radius = light_positions[i].z;
        float light_intensity = light_intensities[i];
        
        // Calculate distance from this pixel to the light
        float dist = distance(screen_coords, light_pos);
        
        if (dist < light_radius) {
            // Calculate light falloff (quadratic)
            float falloff = 1.0 - (dist / light_radius);
            falloff = falloff * falloff;
            
            // Check for occlusion
            float occlusion = calculate_occlusion(light_pos, screen_coords);
            
            // Combine falloff, occlusion, and intensity
            float light_contribution = light_intensity * falloff * occlusion;
            
            // Take maximum light level from any source
            total_light = max(total_light, light_contribution);
        }
    }
    
    // Add ambient light (minimum light level)
    total_light = max(total_light, ambient_light);
    
    // Clamp light level
    total_light = clamp(total_light, 0.0, 1.0);
    
    // Apply darkness (inverse of light)
    float final_darkness = 1.0 - total_light;
    
    // Return darkness as a black overlay with alpha
    return vec4(0.0, 0.0, 0.0, final_darkness);
}
