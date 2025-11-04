// Fragment shader for 2D lighting with raycasted shadows
// Based on: https://icuwanl.wordpress.com/2018/07/05/light-sources-shadows-part-2/
// Note: Uses GLSL ES syntax for LÖVE compatibility (texture2D instead of texture)

uniform vec2 lightPos;           // Light source position (player) in screen coordinates
uniform vec2 screenSize;         // Screen dimensions
uniform float lightRadius;       // Maximum light radius in pixels
uniform float ambientLight;      // Ambient light level (0.0 - 1.0)
uniform float raycastStepSize;   // Step size for raycasting (pixels)
uniform sampler2D blockTexture;  // Texture containing world block solidity data

// Cast a ray from the light source to a specific point
// Returns the light intensity at that point (0.0 = fully shadowed, 1.0 = fully lit)
float castLight(vec2 from, vec2 to) {
    vec2 direction = to - from;
    float totalDistance = length(direction);
    
    // Very close to light source - always fully lit
    if (totalDistance < 2.0) {
        return 1.0;
    }
    
    direction = normalize(direction);
    
    // Ray march from light source toward the target point
    float stepSize = raycastStepSize;
    int numSteps = int(totalDistance / stepSize);
    
    // Limit steps for performance
    if (numSteps > 200) {
        numSteps = 200;
    }
    
    // March along the ray
    for (int i = 1; i < numSteps; i++) {
        float currentDist = float(i) * stepSize;
        vec2 samplePos = from + direction * currentDist;
        vec2 texCoord = samplePos / screenSize;
        
        // Skip if out of bounds
        if (texCoord.x < 0.0 || texCoord.x > 1.0 || texCoord.y < 0.0 || texCoord.y > 1.0) {
            continue;
        }
        
        // Check if there's a solid block at this position
        vec4 blockData = texture2D(blockTexture, texCoord);
        if (blockData.a > 0.5) {
            // Hit a solid block - check if we're past the target point
            if (currentDist < totalDistance - stepSize) {
                return 0.0; // Shadowed
            }
        }
    }
    
    return 1.0; // Path is clear
}

vec4 effect(vec4 color, sampler2D tex, vec2 texture_coords, vec2 screen_coords) {
    // Get the base pixel color
    vec4 pixel = texture2D(tex, texture_coords);
    
    // Calculate distance from current fragment to light source
    float distToLight = length(lightPos - screen_coords);
    
    // Calculate base light intensity with quadratic falloff
    float attenuation;
    if (distToLight > lightRadius) {
        attenuation = 0.0;
    } else {
        attenuation = 1.0 - (distToLight / lightRadius);
        attenuation = attenuation * attenuation; // Quadratic falloff
    }
    
    // Cast ray to check for shadows
    float visibility = castLight(lightPos, screen_coords);
    
    // Combine attenuation and shadow
    float lightIntensity = attenuation * visibility;
    
    // Final light level: ambient + dynamic light
    float finalLight = ambientLight + (1.0 - ambientLight) * lightIntensity;
    
    // Apply lighting to the pixel
    return pixel * vec4(vec3(finalLight), 1.0);
}
