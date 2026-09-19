# Official Godot 4.7 manuals (project-relevant)

Pin: **[docs.godotengine.org/en/4.7](https://docs.godotengine.org/en/4.7/)**. Prefer `/4.7/` over `/stable/` if they ever diverge. Live-fetched 2026-09-19.

Summaries only. Follow the links for full pages.

## Version and defaults

- [Godot 4.7 release](https://godotengine.org/releases/4.7/) — HDR output, Control `offset_transform_*` (visual-only by default; can optionally affect mouse), new Asset Store, inline shader previews, Android export via GABE. None of that is required for this jam.
- [Upgrading 4.6 → 4.7](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)
  - GDScript-breaking items we use: **none**. RichTextLabel image APIs and a few particle/physics signatures changed; we don't call them.
  - **New-project defaults** are `stretch/mode = canvas_items` and `stretch/aspect = expand`. This repo already overrides to `viewport`. Runtime in `main.gd` also forces keep-aspect + fractional scale.
  - Input device IDs for mouse/keyboard are no longer `0`; use `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` if we ever filter by device.
  - Typed-return overrides now require an explicit `return`.
  - Packed-array element sets no longer call the whole-property setter (only matters if we add that pattern).
  - `CanvasItem` line antialiasing no longer adds a feather (lines look thinner than 4.6 if we draw them).

## Pixel-art window / camera

- [Multiple resolutions](https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html)
  - Base size is the **design size**, not a forced monitor mode.
  - `viewport` stretch renders at the base size then scales the framebuffer.
  - Official pixel-art recipe: `viewport` + `keep` (or `expand`) + **`integer`** scale mode. Integer rounds the scale factor **down** (2.5× → 2.0×) so pixels stay even.
  - Default scale mode is `fractional`. This project uses **fractional on purpose** so a laptop editor game tab smaller than 1280×720 letterboxes instead of cropping the dock. `main.gd` sets `Window.CONTENT_SCALE_*` at runtime.
  - Official note: integer scale + Windows "Fullscreen" (not Exclusive) can drop 1px and fall to a worse integer factor.
  - Runtime knobs: `get_tree().root.content_scale_size / mode / aspect / factor`.
  - `viewport` stretch makes slow pan look steppy (fewer distinct pixels). `canvas_items` pans smoother but can blur art. We keep `viewport`.
- [Camera2D.zoom](https://docs.godotengine.org/en/stable/classes/class_camera2d.html) — higher values zoom **in**. X and Y should match. Fonts not on a CanvasLayer look blurry under zoom; HUD is on `CanvasLayer` so it is independent of camera zoom.
- Forum consensus (see [community.md](./community.md)): Default Texture Filter = Nearest; Camera2D zoom in **integer steps**; don't tween zoom through 1.27×. Matches `ZOOM_LEVELS = [1.0, 2.0]` and snap-to-pixel in `project.godot`. Pan is `.round()`ed.

## UI / HUD

- [Using Containers](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_containers.html)
  - Children of a Container **give up** manual `position`/`size`. Nest HBox/VBox/Margin/Panel/Center/Scroll.
  - Size flags: Fill, Expand, Shrink Begin/Center/End, Stretch Ratio.
  - `SubViewportContainer` is the official way to show a SubViewport as a Control.
  - 4.7 also documents `FoldableContainer` and `FlowContainer` — unused here.
- [GUI skinning](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_skinning.html)
  - Theme items: Color, Constant, Font, Font size, Icon, StyleBox.
  - Lookup order: local override → ancestor `theme` → project theme → default theme.
  - Type variations (we use `PaperMuted` on labels).
  - Prefer one Theme on the HUD root over per-node StyleBoxes.
  - Individual scenes preview with the default theme unless the scene root also has the Theme assigned.
- [Control](https://docs.godotengine.org/en/4.7/classes/class_control.html)
  - GUI input is `_gui_input`, filtered by z-order, focus, rect, and `mouse_filter`.
  - `MOUSE_FILTER_STOP = 0` (default) — eats the event; physics picking never sees it.
  - `MOUSE_FILTER_PASS = 1` — this control gets the event; if unhandled it bubbles to parent Controls. **Pass still participates**, which can block SubViewport picking (forum 135181).
  - `MOUSE_FILTER_IGNORE = 2` — node and its rect do not eat mouse. **Does not inherit.** Every full-rect spacer must set it.
  - 4.7 `mouse_behavior_recursive` can force IGNORE on a whole subtree (`MOUSE_BEHAVIOR_DISABLED`). We currently set IGNORE per node instead.
  - GUI is processed **before** physics picking. A leftover full-screen Panel with STOP is why `Area2D` / `CharacterBody2D.input_event` silently dies.
  - `_gui_input` is skipped if a parent Control STOP'd the event, or another Control is on top without IGNORE.

## 2D characters, picking, pens

- [CharacterBody2D](https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html)
  - Script-moved. Use `velocity` + `move_and_slide()` in `_physics_process`. Do **not** multiply velocity by `delta` when using `move_and_slide` (docs call that a common mistake).
  - `MOTION_MODE_FLOATING` — no floor/ceiling; all collisions are walls; slide speed stays constant. Correct for zoo wander (we set this). `wall_min_slide_angle` only applies in FLOATING.
  - `MOTION_MODE_GROUNDED` is the platformer default; do not use it here.
  - `move_and_slide()` returns whether a collision happened; iterate `get_slide_collision_count()`. Animals already stop and re-pause on a slide hit.
- [Using CharacterBody2D](https://docs.godotengine.org/en/4.7/tutorials/physics/using_character_body_2d.html)
  - Don't assign `position` to move; use `move_and_slide` / `move_and_collide`.
  - Slide vs collide: slide for wander-into-fences; collide if we ever want bounce.
- [Viewport.physics_object_picking](https://docs.godotengine.org/en/4.7/classes/class_viewport.html)
  - **Off by default.** `main.gd` turns it on. Pickable objects cap at **64**, order is non-deterministic unless `physics_object_picking_sort` (+ optionally `first_only`).
  - Picking runs only after `_input` / `_gui_input` / `_unhandled_input` leave the event unhandled.

Click-to-inspect: `CollisionObject2D.input_pickable` + `Viewport.physics_object_picking`. Animals (`CharacterBody2D`) and visitors (`Area2D`) both pick. HUD must leave empty space IGNORE.

## Creature rendering / animation

- [2D sprite animation](https://docs.godotengine.org/en/4.7/tutorials/2d/2d_sprite_animation.html)
  - Day-2 plan in ART_PIPELINE: one `AnimationPlayer` driving matching `frame` / `Hframes` on every part `Sprite2D`. That is the official Sprite2D + AnimationPlayer path, not `AnimatedSprite2D` per part.
  - `play()` applies next process tick; call `advance(0)` if a same-frame flip + anim change glitches.
  - Current demo uses procedural bob/`scale.x` facing in `animal.gd` instead of AnimationPlayer.
- [Using TileMaps](https://docs.godotengine.org/en/4.7/tutorials/2d/using_tilemaps.html) — `TileMapLayer` + TileSet. Floor is currently `_draw()` of 100×100 textures. Only switch if we need tile collision/nav; we don't.

## Shaders (palette swap)

- [Your first 2D shader](https://docs.godotengine.org/en/4.7/tutorials/shaders/your_first_shader/your_first_2d_shader.html)
  - `shader_type canvas_item;` then `fragment()` writes `COLOR`.
  - `TEXTURE` + `UV` is the sprite's own texture. Uniforms via `set_shader_parameter("name", value)`.
  - One `ShaderMaterial` shared across part sprites is valid and is what `creature_visuals.gd` does. CanvasItem also has “use parent material.”
- Our shader (`scripts/shaders/palette_swap.gdshader`): sample source, look up `palette` at `(source.r, 0.5)`, keep source alpha. Palettes and sprites must be **nearest**.

## Exhibit thumbnail

- [SubViewport](https://docs.godotengine.org/en/4.7/classes/class_subviewport.html)
  - Does not draw by itself. Needs size ≥ 2×2 and either a `SubViewportContainer` or a `ViewportTexture`.
  - Standalone SubViewports do **not** get input unless inside a container or you `push_input`.
  - HUD thumbnail shares `world_2d` and uses its own `Camera2D`. Keep that camera current **inside the SubViewport**, not the main camera.
  - Default `render_target_update_mode` is `UPDATE_WHEN_VISIBLE`. Fine for the card.

## 4.7 Control offset transforms (future polish)

Release notes: `offset_transform_*` lets you tween a Control without fighting its Container. Visual-only by default, so hover/click rect stays put. Useful later for lab card pop-in; do not use it to fake layout.
