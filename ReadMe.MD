# Kartoffel's Shader Collection for OpenMW

License: GPL-3.0 (inherited from source materials)

This collection contains independent shader modifications:

1. **Toon Shader** - Cel-shading and stylized rendering
2. **Soft Shadow Filter** (`shadows-core`) - Configurable soft shadows
3. (Recommended) **Performance Soft Shadow Filter** (`shadows-performance-core`) - Configurable soft shadows

Mix and match as needed. Shadow filters are mutually exclusive (pick one).

---

## Quick Start

1. **Post-Processing** (`toon.omwfx`) - Install like a regular mod
2. **Core Shaders** - Copy to OpenMW's `resources/shaders/` directory
3. **Settings** - Merge relevant sections into your settings.cfg (see each shader's requirements below). If you want you can just source the example settings.

---

## Folder Structure

**Make a backup of your shaders before modifying!**

```
kart-openmw-shaders-collection/
├── sample-settings-cfg/         <- Reference settings.cfg examples
│   ├── regular budget/
│   └── low budget/
├── toon-post-processing/        <- Install as a mod
│   └── shaders/
│       └── toon.omwfx
├── toon-core/                   <- Copy to OpenMW resources/
│   └── shaders/
│       └── ...
├── shadows-core/                <- Copy to OpenMW resources/
│   └── shaders/
│       └── compatibility/
│           └── shadows_fragment.glsl
└── shadows-performance-core/    <- Copy to OpenMW resources/
    └── shaders/
        └── compatibility/
            └── shadows_fragment.glsl
```

Choose **one** shadow shader (shadows-core OR shadows-performance-core), not both. They overwrite each other. I'd personally recommend the performance shadows.

## Installation

### Post-Processing (`toon-post-processing/`)

Install like any other openmw mod.

### Core Shaders

**MAKE A BACKUP**

Copy the `shaders/` folder contents to your OpenMW installation:

```
<OpenMW Install>/resources/shaders/
```

Example paths:
- Windows: `C:\Program Files\OpenMW\resources\shaders\`
- Linux: `/usr/share/openmw/resources/shaders/`

### settings.cfg Location

- Windows: `C:\Users\<YourName>\Documents\My Games\OpenMW\settings.cfg`
- Linux: `~/.config/openmw/settings.cfg`
- macOS: `~/Library/Application Support/openmw/settings.cfg`

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

---

# Soft Shadow Shaders

Both shaders produce smooth, soft shadows using a 512x512 shadow map instead of the default 2048x2048.

## Performance Comparison

| Shader | Shadow Map | Samples | Notes |
|--------|-----------|---------|-------|
| **Default OpenMW** | 2048x2048 | 1 | Sharp, expensive map |
| **Soft** (shadows-core) | 512x512 | 8 always | Pseudo-PCSS, sin/cos per pixel |
| **Soft Budget** (shadows-performance-core) | 512x512 | 4-16 | Early bail, ~80% pixels exit at 4 |

512 map is 16x cheaper to render than 2048. The extra sampling cost is offset by the smaller map (Probably). Soft Budget is fastest for most scenes.

## Soft (shadows-core)

8-tap spiral disc with pseudo-PCSS (contact shadows tight, distant shadows soft).

```glsl
SHADOWMAP_RES     256.0   // Set lower than settings.cfg for more blur
PENUMBRA_NEAR     1       // Softness of close shadows
PENUMBRA_FAR      3.0     // Softness of distant shadows
```

## Soft Budget (shadows-performance-core)

Grid PCF with early-bail. Samples corners first, skips full filter if fully lit/shadowed.

```glsl
SHADOWMAP_RES   512.0   // Match your settings.cfg
FILTER_SIZE     4       // Samples per axis (expensive to increase)
STRIDE_MIN_PX   2       // Penumbra width: 1.0 tight, 2.0 soft
```

---

# Shadow Settings (settings.cfg)

Both shadow shaders use these settings. See `sample-settings-cfg/` for complete examples.

## Required

```ini
[Shadows]
enable shadows = true
shadow map resolution = 512
```

## Default

```ini
[Shadows]
number of shadow maps = 5
maximum shadow map distance = 8192
shadow fade start = 0.9
polygon offset factor = 2
polygon offset units = 4.0
normal offset distance = 8.0
actor shadows = true
player shadows = true
terrain shadows = true
object shadows = true
```

## Lower End Computers

```ini
[Shadows]
number of shadow maps = 1
maximum shadow map distance = 4096
shadow fade start = 0.9
polygon offset factor = 2
polygon offset units = 4.0
normal offset distance = 8.0
actor shadows = false
player shadows = false
terrain shadows = true
object shadows = true
```

**Notes:**
- 512 resolution is intentional - the filter blurs it anyway
- Fewer shadow maps = less coverage but faster
- Disabling actor/player shadows saves performance, terrain/object shadows give the most visual impact

---

# Credits

- **OpenMW** - Engine and base shaders
- **Jimenez (SIGGRAPH 2014)** - Spiral disc sampling, Interleaved Gradient Noise
- **Wareya** - Plane-dependent shadow filtering, 95% of the budget shadows implementation.
