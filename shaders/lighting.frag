// Fragment shader for 2D lighting with raycasted shadows
// Based on: https://icuwanl.wordpress.com/2018/07/05/light-sources-shadows-part-2/

uniform vec2 lightPos;           // Light source position (player) in screen coordinates
uniform vec2 screenSize;         // Screen dimensions
uniform float lightRadius;       // Maximum light radius in pixels
uniform float ambientLight;      // Ambient light level (0.0 - 1.0)
uniform sampler2D blockTexture;  // Texture containing world block solidity data

// Cast a ray from the light source to check for obstructions
// Returns true if the path is clear (no shadow)
bool isLit(vec2 lightPos, vec2 fragPos, vec2 screenSize) {
    vec2 direction = fragPos - lightPos;
    float distance = length(direction);
    direction = normalize(direction);
    
    // Step size in pixels - smaller = more accurate but slower
    float stepSize = 8.0;
    int maxSteps = int(distance / stepSize);
    
    // Ray march from light to fragment
    for (int i = 1; i < maxSteps; i++) {
        vec2 samplePos = lightPos + direction * (float(i) * stepSize);
        vec2 texCoord = samplePos / screenSize;
        
        // Check if we're sampling within bounds
        if (texCoord.x < 0.0 || texCoord.x > 1.0 || texCoord.y < 0.0 || texCoord.y > 1.0) {
            continue;
        }
        
        // Sample the block texture - if alpha > 0, there's a solid block
        vec4 blockData = texture2D(blockTexture, texCoord);
        if (blockData.a > 0.1) {
            return false; // Path is blocked, fragment is in shadow
        }
    }
    
    return true; // Path is clear, fragment is lit
}

vec4 effect(vec4 color, sampler2D tex, vec2 texture_coords, vec2 screen_coords) {
    // Get the base pixel color from the layer texture
    vec4 pixel = texture2D(tex, texture_coords);
    
    // Calculate distance from current fragment to light source
    float distToLight = length(lightPos - screen_coords);
    
    // If outside light radius, apply only ambient light
    if (distToLight > lightRadius) {
        return pixel * vec4(vec3(ambientLight), 1.0);
    }
    
    // Check if fragment is in shadow
    bool lit = isLit(lightPos, screen_coords, screenSize);
    
    // Calculate light intensity based on distance (quadratic falloff)
    float attenuation = 1.0 - (distToLight / lightRadius);
    attenuation = attenuation * attenuation;
    
    // Calculate final light level
    float finalLight;
    if (lit) {
        // Lit: interpolate between ambient and full brightness based on distance
        finalLight = mix(ambientLight, 1.0, attenuation);
    } else {
        // In shadow: use only ambient light
        finalLight = ambientLight;
    }
    
    // Apply lighting to the pixel
    return pixel * vec4(vec3(finalLight), 1.0);
}
