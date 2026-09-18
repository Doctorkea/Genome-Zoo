# Creature Rendering Pipeline (Godot 4.7, 2D pixel art)

> Verified against the Godot 4.7 release (June 2026) — see the
> [Engine version](#engine-version-godot-47) section below for what changed and what didn't.

## The question

> Will I just have template body styles (round head, bulky head, etc) that have no texture, and I overlay a
> texture on top of it?

Close, but split it into **two different systems** — this is the standard "paper doll" approach used for
modular 2D characters, plus one addition that saves your artist a huge amount of redundant work.

## The two systems

### 1. Shape traits → swappable, fully-drawn parts (paper doll)

Head, Neck, Body, Limbs, and Eyes are **not** blank templates with a texture overlaid — each option (Round
Head, Horned Head, Bulbous Head, ...) is a small, fully-drawn sprite that the artist draws **once**. At
runtime you don't overlay anything onto a shape; you just swap which texture a given `Sprite2D` node is
showing.

- One `Node2D` root per creature ("rig").
- One child `Sprite2D` per trait **slot** (`Head`, `Neck`, `Body`, `Limbs`, `Eyes`), positioned at a fixed
  offset from the root that never changes.
- Changing a trait = calling `sprite.texture = new_texture` on that slot's `Sprite2D`. Nothing moves,
  nothing is re-laid-out.
- Every option for a given slot must share the same canvas size and pivot point, so any Head option lines
  up with any Neck/Body combination. Give the artist a single reference rig image (a grid/pose guide) to
  draw every variant on top of — this is the one thing that has to be consistent across the whole trait
  library.

This is well-established for exactly this use case — see `docs/references.md` for the sources this is based
on (layered `Sprite2D`s per part, one `AnimationPlayer` driving all of them in sync once animation is added).

### 2. Skin/Coat trait → a shared palette-swap shader, not new art per shape

This is the part worth doing differently from a naive "just overlay a texture" approach. If Fur / Scales /
Slime were separate hand-painted textures, your artist would need a separate texture **per shape per skin**
— 3 heads × 3 skins, 3 bodies × 3 skins, etc. That's a combinatorial explosion for a 2-person, 48-hour team.

Instead:

- The artist draws every shape option **once**, in grayscale (luminance only — light/shadow, no color).
- A single canvas-item shader samples that grayscale value and looks it up in a small **palette texture**
  (a 1-pixel-tall strip of colors) to produce the final color, alpha preserved from the source.
- "Fur" / "Scales" / "Slime" become three different palette textures, not three different sets of shape
  art. Swapping skin = swapping one small texture on a shared `ShaderMaterial`, applied to every part
  `Sprite2D` at once so the whole creature recolors consistently in one call.

```glsl
// scripts/shaders/palette_swap.gdshader
shader_type canvas_item;

uniform sampler2D palette : filter_nearest;

void fragment() {
    vec4 source = texture(TEXTURE, UV);
    vec4 result = texture(palette, vec2(source.r, 0.5));
    result.a = source.a;
    COLOR = result;
}
```

Set both the sprite textures and the palette texture's filter to **Nearest** in the Import settings (Godot
defaults to linear filtering, which blurs pixel art).

Trade-off to flag to your artist: this makes skin/coat traits a **color** difference (warm brown fur vs.
cool teal scales vs. glossy green slime), not a different surface **pattern**. That's the right call for a
jam — true alternate patterns per shape are a stretch goal only (see below), not MVP.

## Godot project layout

```
scenes/
  Creature.tscn        # Node2D root + one Sprite2D per slot, see below
scripts/
  creature_visuals.gd  # runtime part/skin swapping (already scaffolded)
  shaders/
    palette_swap.gdshader
art/
  creatures/
    parts/             # {slot}_{option}.png, e.g. head_horned.png — grayscale
    palettes/          # {skin_name}.png — 1px-tall color strips, e.g. scales.png
```

`Creature.tscn` node tree:

```
Creature (Node2D, script: creature_visuals.gd)
├── Body    (Sprite2D)
├── Neck    (Sprite2D)
├── Head    (Sprite2D)
├── Limbs   (Sprite2D)
└── Eyes    (Sprite2D)
```

Draw order = child order in the scene tree (later children draw on top), so order these to match how the
parts actually stack (Body → Limbs → Neck → Head → Eyes is a reasonable default; adjust once real art exists).

## Art checklist for your artist

- **Creatures are side-on** (profile view), not top-down, even though the zoo/pen grid itself is top-down —
  this is the same convention as most 2D zoo/farm sims (side-view characters read as recognizable animals;
  top-down animal silhouettes usually just look like blobs). The rig faces **right** by default; the game
  mirrors the whole creature horizontally when it walks left, so only draw the right-facing version of
  each part.
- The project's base resolution is **640×360** (see [Engine version](#engine-version-godot-47) below), scaled
  up by integer multiples. A full creature should read clearly around 100–160px wide on screen. Suggested
  per-slot canvas sizes for the side-on rig (positions set in `scenes/Creature.tscn`):

  | Slot | Canvas | Notes |
  | --- | --- | --- |
  | Body | 96×56 | horizontal torso, the anchor everything else is positioned around |
  | Head | 48×48 | front of body, raised |
  | Eyes | 16×12 | see open question below on 1 vs. 2 eyes |
  | Mouth | 20×12 | front-bottom of head / snout |
  | Arms (front legs) | 20×32 | front-bottom of body |
  | Legs (back legs) | 20×32 | back-bottom of body |
  | Tail | 36×24 | back of body |

  If you'd rather work at a larger canvas for comfort, use a **clean integer multiple** of the target (e.g.
  draw the body at 384×224 and export at exactly ÷4) rather than an arbitrary size — a non-integer downscale
  blurs/aliases nearest-filtered pixel art and defeats the point of this pipeline.
- Fixed canvas size per slot (same size for every option within that slot, so pivots stay aligned — sizes
  can differ *between* slots, per the table above).
- One shared reference/pose guide to draw every shape option on top of, so pivots line up.
- Shape art (`art/creatures/parts/`) is **grayscale only** — no color. Use luminance for shading (darker =
  shadow, lighter = highlight); the palette shader adds all color at runtime.
- Palette textures (`art/creatures/palettes/`) are tiny — a handful of pixels wide, 1 pixel tall, each pixel
  a color stop from dark to light.
- Import settings on every texture: Filter → **Nearest** (Project Settings → Rendering → Textures →
  Canvas Textures → Default Texture Filter, plus per-file overrides as needed) to keep pixel art crisp.

## Roadmap

1. **MVP (Day 1)** — static idle pose only. Swap textures per slot, apply palette shader for skin. This is
   all the trait system needs for the DNA Lab loop to be visible and functional.
2. **Animation sync (Day 2, if time)** — give every part `Sprite2D` matching `Hframes`, drive their shared
   `frame` property from one `AnimationPlayer` so idle/walk/trick animations stay in sync across every part
   regardless of which shape is equipped.
3. **Stretch** — true alternate surface patterns (not just palette recolors) for skin traits, as an
   additional swappable texture layer rather than a shader, once the MVP loop is proven and there's spare
   art time.

## Starter code

- `scripts/creature_visuals.gd` — swaps part textures per slot and drives the shared palette-swap material.
- `scripts/shaders/palette_swap.gdshader` — the shader above.
- `scenes/Creature.tscn` — the node tree above, ready for the artist's textures to be dropped in.

## Engine version: Godot 4.7

This project targets **Godot 4.7** (`config/features` in `project.godot`), released 18 June 2026. Checked
against the [4.6→4.7 migration guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html):

- **Nothing in this pipeline needed code changes.** None of 4.7's breaking API changes touch `Sprite2D`,
  `Node2D`, `ShaderMaterial`, canvas-item shaders, or typed `Array`/`Dictionary` usage the way we use them.
  `creature_visuals.gd` and `palette_swap.gdshader` are unaffected as written.
- **One default did change and matters for us:** new projects created in 4.7 default to
  `display/window/stretch/mode = canvas_items` and `stretch/aspect = expand` (previously `disabled`/`keep`).
  Left alone, that's the wrong call for pixel art — non-integer scaling blurs/distorts grayscale part art and
  makes the palette shader's nearest-neighbor lookup look inconsistent at different window sizes.
- **Fix, already applied in `project.godot`:** explicit `[display]` block setting a 640×360 base resolution,
  `stretch/mode = "viewport"`, `stretch/aspect = "keep"`, and `stretch/scale_mode = "integer"` — the
  standard pixel-art setup, rendering at the low base resolution and only ever scaling by whole numbers.
  This makes the project's scaling behavior explicit and stable regardless of which Godot version opens it,
  rather than riding on whatever the engine's current default happens to be.
- Everything else new in 4.7 (HDR display output, Control offset transforms, the new Asset Store,
  `DrawableTexture2D`, standalone Android export) is unrelated to this pipeline — nothing to act on there.

### Renderer: Compatibility, not Forward+

The project uses the **Compatibility** (OpenGL 3.3) renderer, set via `renderer/rendering_method` in
`project.godot`, instead of Godot's default **Forward+** (Vulkan).

This isn't just a stylistic choice — Forward+ **crashed the editor on open** on a machine with an Intel HD
Graphics 620 integrated GPU (confirmed via Windows crash dumps: `vulkan-1.dll` and Intel's Vulkan driver
`igvk64.dll` were loaded at the moment of the crash). Older/integrated Intel GPUs have historically weak
Vulkan driver support, and this is a known class of crash for Godot 4's Forward+ renderer on that hardware.
Compatibility mode doesn't touch Vulkan at all.

It's also just the right renderer for this project regardless of the crash: Forward+'s clustered
lighting/3D pipeline is overkill for 2D pixel art, and Compatibility has lower overhead for exactly the kind
of sprite-stacking + simple shader work this game does.

If a teammate hits a similar "editor crashes on opening the project" issue on a different machine, the
general checklist is:
1. Confirm the renderer in `project.godot` → `[rendering] renderer/rendering_method` is `gl_compatibility`
   (it should already be, from this commit).
2. Update GPU drivers — this alone fixes many Forward+/Vulkan crashes even without switching renderers.
3. As a last resort, launch the editor with `--rendering-driver opengl3` once to force Compatibility even
   if a stale editor setting is overriding the project setting.

## References

See [`references.md`](./references.md) for the specific threads/repos/shaders this pipeline is based on.
