# Kartoffel's Shader Collection for OpenMW

License: GPL-3.0 (inherited from source materials)

This collection contains two independent shader modifications:

1. **Toon Shader** - Cel-shading and stylized rendering
2. **Soft Shadow Filter** - Blurred shadows at low resolution

You can use either or both.

---

## Quick Start

1. **Post-Processing** (`toon.omwfx`) - Install like a regular mod. Works standalone, but best paired with core shaders.
2. **Core Shaders** - Copy to your OpenMW installation directory (see Installation below). Edit them by opening the directed file.
3. **Settings** - Follow the settings.cfg sections below, or just copy the included settings.cfg. If you use the included settings.cfg you may need to adjust it to your game resolution and UI scale. This can be done in the file, or in the openmw launcher.

---

## Folder Structure
**Make a backup before touching the core shaders!**
```
kartoffel-shaders-3/
├── toon-post-processing/   <- Install as a mod
│   └── shaders/
│       └── toon.omwfx
├── toon-core/              <- Copy to OpenMW root
│   └── shaders/
│       ├── compatibility/
│       │   ├── objects.frag
│       │   ├── terrain.frag
│       │   ├── groundcover.frag
│       │   └── sky.frag
│       └── lib/light/
│           └── lighting_toon.glsl
└── shadows-core/           <- Copy to OpenMW root
    └── shaders/
        └── compatibility/
            └── shadows_fragment.glsl
```

## Installation

### Post-Processing Shader (`toon-post-processing/`)

Install like any other post-processing mod. The `shaders/` folder goes into your data files.

### Core Shaders (`toon-core/` and `shadows-core/`)

These replace OpenMW's built-in shaders. **Make a backup first!**

Copy the contents of the `shaders/` folder to:
```
<OpenMW Install>/resources/shaders/
```

Where `<OpenMW Install>` is the directory containing `openmw.exe`.

Example paths:
- Windows: `C:\Program Files\OpenMW\resources\shaders\`
- Linux: `/usr/share/openmw/resources/shaders/`
- Portable: `./resources/shaders/` (relative to openmw.exe)

You can install `toon-core` and `shadows-core` independently - they don't depend on each other.

### Settings (settings.cfg)

Your settings.cfg is located in your OpenMW user data folder:
- Windows: `C:\Users\<YourName>\Documents\My Games\OpenMW\settings.cfg`
- Linux: `~/.config/openmw/settings.cfg`
- macOS: `~/Library/Application Support/openmw/settings.cfg`

You can either edit the file directly or copy the included sample settings.cfg to this location. If you use the included settings.cfg you may need to adjust it to your game resolution and UI scale. This can be done in the file, or in the openmw launcher.

---

# Toon Shader

A two-layer toon shader system:

- **Core Shaders** - Texture simplification applied during rendering
- **Post-Processing** - Cel-shading, outlines, and color banding applied after


## Core Shader Configuration

Modified via: `<OpenMW Install>/resources/shaders/lib/light/lighting_toon.glsl`

Open it in a text editor. You have 5 knobs to mess with:

```glsl
TOON_TEXTURE_FLATTEN    0.5   // 0.0 = off, 0.3 = subtle, 0.6 = very flat/painted
TOON_TEXTURE_MIDPOINT   0.55  // Target brightness for flattening
TOON_MIP_BIAS           1.0   // 0.0 = sharp, 1.0 = soft, 2.0 = very soft
TOON_POSTERIZE_LEVELS   256   // 256 = off, 24 = subtle, 16 = anime, 8 = stylized
TOON_POSTERIZE_STRENGTH 0.0   // 0.0 = off, 0.3 = subtle, 1.0 = hard bands
```

**Recommendations:**

- `TOON_MIP_BIAS` is the most impactful - it forces blurrier texture mip levels, hiding fine detail. This is probably the most useful setting for that "TOON" feel. You can force the game into a very low detail mode.
- `TOON_TEXTURE_FLATTEN` and `TOON_TEXTURE_MIDPOINT` will make the game look washed out, but that can be adjusted in post-processing. Helpful for reducing the amount of colors.
- `TOON_POSTERIZE_LEVELS` and `TOON_POSTERIZE_STRENGTH` work together to reduce the color palette.

### Post-Processing (toon.omwfx)

All settings are configurable in-game via the post-processing menu (F3):

**Outlines**
- Thickness (0-8)
- Strength
- Edge sensitivity
- Color and/or scene matching

**Cel Shading**
- Shading steps
- Brightness lift
- Saturation
- Shadow tint color

**Effects**
- Glow cel shading for fire/magic
- Sky cel shading

## Required Settings (settings.cfg)

```ini
[Shaders]
force shaders = true
force per pixel lighting = true
clamp lighting = false
lighting method = shaders
classic falloff = false
minimum interior brightness = 0.5

[Post Processing]
enabled = true
transparent postpass = true
chain = toon
```

## Optional Performance Settings

```ini
[Camera]
small feature culling = true
small feature culling pixel size = 2.0

[Shaders]
auto use object normal maps = false
auto use object specular maps = false
auto use terrain normal maps = false
auto use terrain specular maps = false
soft particles = false
pixel size = 4.0
```

---

# Soft Shadow Filter

8-tap spiral disc sampler with pseudo-PCSS. Produces smooth, soft shadows using a low-resolution shadow map.

## Files Modified

| File | Changes |
|------|---------|
| `shadows_fragment.glsl` | Complete rewrite - replaces stock 1-tap with 8-tap spiral disc |

## Configuration (compatibility/shadows_fragment.glsl)

```glsl
SHADOWMAP_RES     256.0   // Match or lower than settings.cfg value
PENUMBRA_NEAR     1       // Contact shadow tightness
PENUMBRA_FAR      3.0     // Distant shadow softness
FILTER_MIN_TEXELS 1.3     // Minimum filter spread
```

## Required Settings (settings.cfg)

```ini
[Shadows]
enable shadows = true
shadow map resolution = 512
```

## Recommended Settings (settings.cfg)

```ini
[Shadows]
number of shadow maps = 5
maximum shadow map distance = 4096
shadow fade start = 0.9
polygon offset factor = 2
polygon offset units = 4.0
normal offset distance = 8.0
```

The 512 resolution is intentional - the filter blurs it anyway, so higher resolutions cost more for no visual benefit. You could go to 1024, but would have to adjust the knobs at the top of the shader.

## Technical Details

**Based on:**
- Jimenez (SIGGRAPH 2014) - spiral disc with alternating flip, IGN rotation
- Wareya - plane-dependent filtering

**Features:**
- Interleaved Gradient Noise rotation for smooth gradients
- Distance-based penumbra (contact shadows tight, distant shadows soft)
- Plane-dependent filtering (kernel aligns to surface orientation)

**Performance vs Stock:**

Stock OpenMW uses 1-tap sampling, requiring high-resolution shadow maps (2048x2048).
This filter uses 8 taps + some other computations on a 512x512 map.

Rendering a 512 map is 16x cheaper than 2048. The extra sampling (taps + math) cost is covered by not having to render the larger shadow map. Probably.
