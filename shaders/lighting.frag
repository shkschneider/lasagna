// Fragment shader for 2D lighting with raycasted shadows
// Based on: https://icuwanl.wordpress.com/2018/07/05/light-sources-shadows-part-2/
// This shader generates a light map that will be multiplied over the scene
// Note: Uses GLSL ES syntax for LÖVE compatibility (texture2D instead of texture)

uniform vec2 lightPos;           // Light source position (player) in screen coordinates
uniform vec2 screenSize;         // Screen dimensions
uniform float lightRadius;       // Maximum light radius in pixels
uniform float raycastStepSize;   // Step size for raycasting (pixels)
uniform sampler2D blockTexture;  // Texture containing world block solidity data

// Cast a ray from the light source to check if a point is lit
// Returns 1.0 if lit, 0.0 if in shadow
float castLight(vec2 from, vec2 to) {
    vec2 direction = to - from;
    float totalDistance = length(direction);
    
    // Very close to light source - always lit
    if (totalDistance < 1.0) {
        return 1.0;
    }
    
    direction = normalize(direction);
    
    // Use smaller step size for more accurate shadow edges
    float stepSize = raycastStepSize;
    int numSteps = int(totalDistance / stepSize);
    
    // Limit steps for performance
    if (numSteps > 300) {
        numSteps = 300;
    }
    
    // March along the ray
    for (int i = 1; i < numSteps; i++) {
        float currentDist = float(i) * stepSize;
        
        // Stop if we've gone past the target
        if (currentDist >= totalDistance) {
            break;
        }
        
        vec2 samplePos = from + direction * currentDist;
        vec2 texCoord = samplePos / screenSize;
        
        // Skip if out of bounds
        if (texCoord.x < 0.0 || texCoord.x > 1.0 || texCoord.y < 0.0 || texCoord.y > 1.0) {
            continue;
        }
        
        // Check if there's a solid block at this position
        vec4 blockData = texture2D(blockTexture, texCoord);
        if (blockData.a > 0.5) {
            // Hit a solid block - this point is in shadow
            return 0.0;
        }
    }
    
    return 1.0; // Path is clear, fully lit
}

vec4 effect(vec4 color, sampler2D tex, vec2 texture_coords, vec2 screen_coords) {
    // Calculate distance from this pixel to light source
    float distToLight = length(lightPos - screen_coords);
    
    // Calculate light intensity with distance falloff
    float attenuation;
    if (distToLight > lightRadius) {
        attenuation = 0.0;
    } else {
        attenuation = 1.0 - (distToLight / lightRadius);
        attenuation = attenuation * attenuation; // Quadratic falloff
    }
    
    // Cast ray to check for shadows
    float visibility = castLight(lightPos, screen_coords);
    
    // Combine distance attenuation and shadow visibility
    float lightIntensity = attenuation * visibility;
    
    // Return light value for additive blending with ambient
    // The canvas is cleared to ambient, and we add dynamic light
    return vec4(vec3(lightIntensity), 1.0);
}
