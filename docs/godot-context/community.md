# Community threads (forums, shaders, addons)

Summaries of sources already cited in [`../references.md`](../references.md), plus extra threads that match this project's HUD, picking, and pixel-art setup. Live-fetched 2026-09-19.

## Paper-doll / layered sprites

- [How to layer sprites ("dress up a character") in 2D — Godot Forum](https://forum.godotengine.org/t/how-to-layer-sprites-dress-up-a-character-in-2d/11898)
  - Two approaches: live stacked spritesheets driven by one AnimationPlayer, or bake the stack to a texture.
  - Author landed on **stacked sprites + AnimationPlayer**. That is our Day-2 plan. Do not bake. Jam idle bob in `animal.gd` is a stand-in.
- [Layered pixel-art outfits — r/godot](https://www.reddit.com/r/godot/comments/1msnvlh/guide_layered_and_animated_pixel_art/)
- [ldev1996/sprite-customizer-2d-godot](https://github.com/ldev1996/sprite-customizer-2d-godot) — addon, not used
- [lucimoon/custom-sprite-2d](https://github.com/lucimoon/custom-sprite-2d) — layered sprites, per-layer texture swap, grayscale color modulate, AnimationPlayer sync. Closest addon to our pipeline; we already rolled our own `CreatureVisuals`.

## Palette swap

- [Palette Swap (no recolor / recolor) — Godot Shaders](https://godotshaders.com/shader/palette-swap-no-recolor-recolor/)
  - **No-recolor:** compare pixel color to N uniforms with `distance()` (float-unsafe `==`). Fine for 5-color sprites, not for continuous grayscale shading.
  - **Recolor (ours):** encode lookup in the source channels, sample a palette texture, copy alpha. Their snippet uses `color.rg`; we use **`source.r` only** (luminance) and `y = 0.5` on a 1px-tall strip.
  - `hint_color` in that 2021 snippet is now `source_color` in Godot 4.
- [KoBeWi/Godot-Palette-Swap-Shader](https://github.com/KoBeWi/Godot-Palette-Swap-Shader) — animated palettes. Stretch if slime/scales need cycling.
- [Creating A Simple Palette Swap Shader in Godot 4.2 (YouTube)](https://www.youtube.com/watch?v=Pp55iVPxN4Y)
- [Palette swap + opacity — r/godot](https://www.reddit.com/r/godot/comments/pjcfc0/help_with_a_palette_swap_shader_affecting_opacity/) — keep `result.a = source.a` (we already do).
- [Introduction to Shaders in Godot 4 — Kodeco](https://www.kodeco.com/43354079-introduction-to-shaders-in-godot-4/page/2) — luminance weights if we ever sample more than `.r`.

## HUD vs world clicks (critical)

These confirm `.cursor/skills/godot-gui/SKILL.md`.

- [UI elements block Area2D mouse detection](https://forum.godotengine.org/t/ui-elements-block-area2ds-mouse-detection/78150)
  - `z_index` is **draw order only** for Controls. Input follows tree + `mouse_filter`.
  - Debugger → Misc → **Last Clicked Control** to find the eater.
  - `mouse_filter` **does not inherit**. Full-rect roots default to STOP. One user “fixed” it by setting every Control to Pass — that still lets overlays participate. Prefer IGNORE on spacers, STOP only on real buttons/panels.
- [SubViewportContainer blocks mouse input](https://forum.godotengine.org/t/subviewportcontainer-blocks-mouse-input/98499)
  - HUD overlay IGNORE + SubViewport **Physics Object Picking** for in-viewport Area2D.
  - Blind `push_input` from `_input` duplicates events (dialogue skip). Don't copy that snippet onto the thumbnail.
- [Confused on Control → SubViewport filtering](https://forum.godotengine.org/t/confused-on-propagation-and-filtering-of-input-events-through-controls-to-subviewport/135181)
  - **Pass can still block SubViewport picking.** IGNORE on layout-only overlays is the working combination with camera + object picking.
- [Area2D not detecting input_event whilst in SubViewport](https://forum.godotengine.org/t/area2d-not-detecting-input-event-whilst-in-subviewport/98287)
  - Enabling Object Picking on a SubViewport **handles** the event, so sibling world Area2Ds in the root viewport stop receiving it.
  - Our thumbnail shares `world_2d` and is a small card, not a full-screen world view — keep it that way. Do not enable picking on the thumb SubViewport unless we want clicks on the card to select the real animal.
- [SubViewportContainer blocking sibling mouse events](https://forum.godotengine.org/t/subviewportcontainer-blocking-mouse-events-of-its-siblings/103300)
- [Passing input through a Viewport to Area2Ds](https://forum.godotengine.org/t/passing-input-through-a-viewport-to-area2ds/37918) — if not a direct child of SubViewportContainer, use `push_input`, not `push_unhandled_input`.
- [Mouse in Area2D not detected (not mouse_filter)](https://forum.godotengine.org/t/mouse-in-area2d-not-detected-and-no-its-not-a-control-mouse-filter-issue/113255)
  - `_input()` + `accept_event()` bypasses `mouse_filter`. Don't do that on HUD wrappers.
- [Collider-before-Control on TileMapLayer](https://stackoverflow.com/questions/79515048/how-do-i-make-my-godot-2d-game-resolve-input-on-colliders-before-control) — `_unhandled_input` + `intersect_point` + `set_input_as_handled` if we ever need empty-floor clicks.

## Pixel-art stretch / zoom

- [How to control scaling algorithm](https://forum.godotengine.org/t/how-to-control-scaling-algorithm/83353) — Nearest default filter; stretch docs, not `Image.interpolate`.
- [Pixel game looks weird](https://forum.godotengine.org/t/how-to-make-the-pixel-not-weird-for-pixel-game/42308) — fractional scale (e.g. 2.5×) makes uneven pixels; integer scale fixes it. We accept fractional in the **editor tab** so the 1280×720 HUD stays fully visible.
- [Pixels flickering when changing camera zoom](https://forum.godotengine.org/t/pixels-flickering-when-changing-camera-zoom/76194) — don't lerp/tween zoom through non-integers. Snap camera position (we `.round()` pan). Integer zoom “won't be smooth”; that is the correct trade-off for this game.
- [Crisp pixel art on large monitors](https://forum.godotengine.org/t/cant-figure-out-how-to-make-my-pixel-art-game-looks-chrisp-on-large-monitors/76054) — don't scale sprites; zoom the camera in 2/4/8 steps; Nearest import.
- [CanvasLayer + 8× Camera2D zoom](https://forum.godotengine.org/t/canvaslayer-and-a-2d-camera-with-8x-zoom/126226) — HUD on CanvasLayer is independent of Camera2D zoom.

## Engine / renderer / tooling

- [Godot 4.7 changelog](https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)
- Compatibility renderer is required here: Forward+ crashed this hardware (`vulkan-1.dll` / Intel HD 620). Do not switch `rendering_method` back to `forward_plus`.
- [alexmeckes/godot-mcp](https://github.com/alexmeckes/godot-mcp) — 99 tools; file tools always; live/runtime needs AI Bridge on port **6550**.
- [alexmeckes/godot-claude-skills](https://github.com/alexmeckes/godot-claude-skills) — five skills; already copied under `.cursor/skills/`.
