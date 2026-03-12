# Asset Specs

Use this doc when creating or requesting new runtime-facing visual assets for ZepBall.
This is the project-facing style/spec contract. Workflow requirements for adding/removing assets still live in `.agent/SOP/critical-workflows.md`.

## Why This Lives In `System/`

These are runtime contracts, not just process notes:
- asset categories map directly to live folders under `assets/graphics/`
- code expects certain dimensions, transparency, scaling behavior, and readability thresholds
- new features should match the existing visual language instead of introducing one-off art directions

## Current Visual Direction

ZepBall uses a clean arcade look:
- bold silhouettes
- bright saturated accent colors on gameplay objects
- dark, subdued backgrounds so gameplay remains readable
- simple geometric forms over illustration-heavy detail
- effects communicated through glow, tint, pulse, and shape language rather than dense texture work

When in doubt, favor clarity over ornament. Most assets are viewed quickly during active play, not in a static gallery.

## General Rules

- Prefer transparent PNG for gameplay sprites/icons and JPG for full-screen backgrounds.
- Keep the main shape centered and readable at a small on-screen size.
- Avoid text, numerals, tiny symbols, or thin detail that disappears when scaled down.
- Use one strong idea per asset. If the icon needs explanation to read, simplify it.
- Match the existing palette bias:
  - beneficial / active / safe: green, cyan, gold
  - risky / negative / dangerous: red, orange-red
  - neutral / inert / structural: grey, muted blue
  - mystery / special-case: yellow
- Favor simple gradients, inner glow, and rim light over noisy texture overlays.
- Do not bake UI labels, borders, or HUD framing into the art.
- Leave some transparent breathing room around icons so scaling and glow effects do not feel cramped.

## Runtime Asset Contracts

### Power-Up Icons and Special Pickup Symbols

Observed current assets:
- Source folder: `assets/graphics/powerups/`
- Typical source size: around `181x182`
- Force Arrow source example: `200x173`
- Runtime consumer: `scripts/power_up.gd`
- Runtime behavior: power-up icons are uniformly scaled to roughly `40px` on screen

Requirements:
- Format: transparent PNG
- Shape: centered single-icon composition
- Readability target: must remain legible at `40x40`
- Background: fully transparent
- Detail level: low to medium; silhouette first, internal detail second
- Use-case fit:
  - standard pickups should read as a single emblem
  - hazard/special-tile icons should still work when repurposed inside `POWERUP_BRICK` or special tile contexts

Good examples from current usage:
- `expand.png`
- `mystery.png`
- `arrow_down_right.png`

Prompt template:

```text
Create a single arcade game power-up icon on a transparent background. Centered composition, bold silhouette, high contrast, clean geometric styling, minimal detail, soft glow-ready edges, no text, no UI frame, readable at 40x40 pixels. Theme: <describe mechanic>. Primary colors: <palette>. Keep the icon simple enough for fast gameplay readability.
```

### Brick and Field Tile Sprites

Observed current assets:
- Source folder: `assets/graphics/bricks/`
- Standard brick source size: `32x32`
- Runtime target size: scaled to `48x48`
- Special cases can be larger and are normalized to the target size at runtime
- Runtime consumer: `scripts/brick.gd`

Requirements:
- Format: transparent PNG
- Default source size for standard tiles: `32x32`
- Composition: centered shape with a strong outer silhouette
- Color family should fit the existing elemental palette
- Variants should stay obviously related when producing:
  - normal vs glossy / stronger
  - shielded / damaged / empowered
  - shape families such as square, diamond, polygon

Guidance:
- Normal brick art should feel solid and readable first, decorative second.
- “Glossy” or stronger variants should imply tougher state without becoming visually noisy.
- Special tiles can use larger source art if necessary, but they must still scale cleanly to a `48px` footprint.
- If the tile has a directional or paired meaning, that meaning must be visible from the sprite alone.

Prompt template:

```text
Create a transparent-background arcade tile sprite for a breakout-style game. Clean geometric silhouette, centered composition, bright readable color, subtle highlight/shading, minimal texture noise, no text. The tile should read clearly when scaled from 32x32 source art to a 48x48 in-game footprint. Theme: <describe tile behavior>. Variant style: <normal/glossy/shielded/etc>.
```

### Backgrounds

Observed current assets:
- Source folder: `assets/graphics/backgrounds/`
- Current shipped size: `1024x576` (16:9)
- Runtime consumer: `scripts/main_background_manager.gd`
- Runtime behavior: stretched full-screen and dimmed to alpha `0.85`
- Note: the gameplay window is resizable but locks to 16:9 aspect ratio

Requirements:
- Format: JPG
- Size: `1024x576` (16:9) — do not use square sources; they will distort when stretched to a 16:9 viewport
- Style: dark, subdued, low-distraction, playfield-friendly
- No text, logos, or focal subjects that compete with the ball/paddle/bricks
- Avoid harsh contrast bands or bright hotspots near the center of the play area

Guidance:
- Backgrounds should support the arcade field, not become the point of attention.
- Space/nebula/minimal abstract directions fit the current set well.
- Use depth, gradient, light haze, and sparse structure over high-frequency detail.
- Existing assets in the repo were generated at 1024x1024 and are acceptable for now; replace or regenerate them at 1024x576 when refreshing the set.

Prompt template:

```text
Create a 1024x576 widescreen background for an arcade breakout game. Dark, refined, low-distraction, subtle sci-fi/space atmosphere, soft gradients, restrained contrast, no text, no characters, no large central focal object. The image should remain readable after being dimmed and stretched full-screen behind bright gameplay elements.
```

### Paddle Variants

Observed current assets:
- Source folder: `assets/graphics/paddles/`
- Current active source example: `104x24`
- Runtime consumer: `scenes/gameplay/paddle.tscn`
- Runtime behavior: rotated 90 degrees and scaled at runtime

Requirements:
- Format: transparent PNG
- Keep the same general aspect ratio unless the runtime contract changes
- Preserve strong endcaps and center body readability after rotation
- Avoid overly thin decorative detail that disappears when rotated/scaled

Good fit:
- damage / curse / empowered state variants
- module-state visuals
- split / altered-state overlays if future features need them

Prompt template:

```text
Create a transparent arcade paddle sprite for a breakout-style game. Wide horizontal source image intended to be rotated vertically in-game, clean futuristic shape, bright readable edges, minimal noise, no text. Keep strong endcaps and a simple center body so the paddle remains readable during fast motion. Theme: <describe state>.
```

### Ball Variants

Observed current assets:
- Source folder: `assets/graphics/balls/`
- Current active source example: `1735x1714`
- Runtime consumer: `scenes/gameplay/ball.tscn`
- Runtime behavior: heavily scaled down; collision radius is independent of visual source size

Requirements:
- Format: transparent PNG
- Visual should still read as a clean sphere/disc when scaled very small
- Avoid tiny inset details or lettering
- Use strong gradient/light direction instead of complex texture work

Prompt template:

```text
Create a transparent arcade ball sprite for a breakout-style game. Clean glossy sphere, strong highlight, simple shading, no text, no background, highly readable when scaled very small in motion. Theme/color: <describe variant>.
```

## Prompting Instructions For New Assets

When asking an artist or image model for new work:

- Name the feature first, then the gameplay meaning.
- Specify the asset type (`power-up icon`, `tile sprite`, `background`, `paddle state`, `ball variant`).
- State the file format and canvas expectation.
- State the readability target.
- State what to avoid.

Recommended prompt structure:

```text
Create a <asset type> for ZepBall, a clean arcade breakout game.
Purpose: <what the asset represents in gameplay>.
Format: <PNG transparent / JPG 1024x1024>.
Composition: <centered icon / full-screen background / tile silhouette>.
Style: bold geometric arcade art, readable, minimal noise, no text.
Colors: <palette guidance>.
Readability target: <40x40 icon / 48px tile / dimmed full-screen background>.
Avoid: <text / detailed scenery / muddy colors / thin detail>.
```

## Feature Request Checklist

For any new asset request, include:
- feature name
- asset type
- target folder
- filename proposal
- gameplay meaning
- whether it needs state variants
- whether it needs matching VFX or HUD treatment
- whether editor preview support is needed

## Delivery Checklist

- Asset matches the runtime contract for its category
- File naming is lowercase snake_case
- File lands in the correct `assets/graphics/` folder
- Runtime references are updated
- `.agent/System/used-assets.md` or `.agent/System/unused-assets.md` is updated if usage changed
- If the asset introduces new visual rules worth preserving, update this doc

## Representative Current Files

- Power-up icons:
  - `assets/graphics/powerups/expand.png`
  - `assets/graphics/powerups/mystery.png`
  - `assets/graphics/powerups/arrow_down_right.png`
- Backgrounds:
  - `assets/graphics/backgrounds/bg_refined_1_1769629758259.jpg`
  - `assets/graphics/backgrounds/bg_nebula_dark_1769629799342.jpg`
  - `assets/graphics/backgrounds/bg_stars_subtle_1769629782553.jpg`
- Bricks / tiles:
  - `assets/graphics/bricks/element_blue_square.png`
  - `assets/graphics/bricks/element_blue_square_glossy.png`
  - `assets/graphics/bricks/special_bomb.png`
- Paddle / ball:
  - `assets/graphics/paddles/paddleBlu.png`
  - `assets/graphics/balls/blue_ball.png`

**Last Updated:** 2026-03-11
