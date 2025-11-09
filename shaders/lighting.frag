// Fragment shader for 2D lighting with raycasted shadows
// Based on: https://icuwanl.wordpress.com/2018/07/05/light-sources-shadows-part-2/
// This shader generates a light map that will be multiplied over the scene
// Note: Uses GLSL ES syntax for LÖVE compatibility (texture2D instead of texture)

uniform vec2 lightPos;           // Light source position (player) in screen coordinates
uniform vec2 screenSize;         // Screen dimensions
uniform float lightRadius;       // Maximum light radius in pixels
uniform float raycastStepSize;   // Step size for raycasting (pixels)
uniform sampler2D blockTexture;  // Texture containing world block solidity data

const float BLOCK_SIZE = 16.0;   // Size of one block in pixels
const float SURFACE_LIGHT = 0.5; // How much to light up surfaces we hit (0.0-1.0)

// Cast a ray from the light source to check if a point is lit
// Returns visibility value: 1.0 if fully lit, 0.0 if in deep shadow, or partial for surfaces
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
            // Hit a solid block
            float distToBlock = currentDist;
            float distBeyondBlock = totalDistance - distToBlock;
            
            // If we're within half a block's width from the block surface, add surface lighting
            if (distBeyondBlock < BLOCK_SIZE * 0.5) {
                // Gradient: full surface light at block edge, fading out
                float surfaceFactor = 1.0 - (distBeyondBlock / (BLOCK_SIZE * 0.5));
                return SURFACE_LIGHT * surfaceFactor;
            }
            
            // Deep shadow beyond surface light range
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
    
    // Reduce overall light strength (0.7 = 70% strength)
    lightIntensity = lightIntensity * 0.7;
    
    // Return light value for additive blending with ambient
    // The canvas is cleared to ambient, and we add dynamic light
    return vec4(vec3(lightIntensity), 1.0);
}
