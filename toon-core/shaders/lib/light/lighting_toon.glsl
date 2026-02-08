#ifndef LIB_LIGHT_LIGHTING_TOON
#define LIB_LIGHT_LIGHTING_TOON

// ============================================================================
// Toon Texture Flattening for OpenMW
//
// Provides texture contrast reduction, mip-biased sampling, and soft
// posterization to give textures an illustrated/painted look.
// All toon lighting is handled in post-processing (toon.omwfx).
// ============================================================================

// --- Configuration -----------------------------------------------------------

// Texture flattening: pulls texture contrast toward midtone for illustrated look
// 0.0 = no flattening, 0.3 = subtle, 0.6 = very flat/painted
#ifndef TOON_TEXTURE_FLATTEN
#define TOON_TEXTURE_FLATTEN .5
#endif

// Texture flatten midpoint (the value textures get pulled toward)
#ifndef TOON_TEXTURE_MIDPOINT
#define TOON_TEXTURE_MIDPOINT 0.55
#endif

// Mip bias: positive = sample blurrier mip, hides fine texture noise/grain
// 0.0 = no blur, 1.0 = one mip level blurrier, 2.0 = very soft
#ifndef TOON_MIP_BIAS
#define TOON_MIP_BIAS 1.0
#endif

// Color posterization: number of distinct levels per channel
// 256 = no posterization, 24 = subtle, 16 = anime palette, 8 = stylized
#ifndef TOON_POSTERIZE_LEVELS
#define TOON_POSTERIZE_LEVELS 256
#endif

// Posterize strength: how much to blend toward quantized colors
// 0.0 = disabled, 0.3 = subtle, 0.6 = visible bands, 1.0 = hard steps
#ifndef TOON_POSTERIZE_STRENGTH
#define TOON_POSTERIZE_STRENGTH 0.0
#endif

// --- Texture functions -------------------------------------------------------

// Mip-biased texture sampling: use instead of texture2D for diffuse maps
// to blur out fine texture detail (cracks, grain, noise).
// Always applies bias — set TOON_MIP_BIAS to 0.0 to disable.
#define toonTexture2D(sampler, uv) texture2D(sampler, uv, TOON_MIP_BIAS)

// Flatten texture value range toward midpoint for an illustrated/painted look.
// Combines contrast reduction, soft posterization, and saturation compensation.
vec3 flattenTexture(vec3 texColor)
{
    // Pull each channel's brightness toward the midpoint
    vec3 flattened = mix(texColor, vec3(TOON_TEXTURE_MIDPOINT), TOON_TEXTURE_FLATTEN);

    // Soft posterize: blend between original and hard-posterized to reduce
    // banding artifacts while still simplifying the color palette
    vec3 posterized = floor(flattened * float(TOON_POSTERIZE_LEVELS) + 0.5) / float(TOON_POSTERIZE_LEVELS);
    flattened = mix(flattened, posterized, TOON_POSTERIZE_STRENGTH);

    // Boost saturation to compensate for contrast/detail loss
    float luma = dot(flattened, vec3(0.3, 0.6, 0.1));
    return mix(vec3(luma), flattened, 1.0 + TOON_TEXTURE_FLATTEN * 0.5);
}

#endif
