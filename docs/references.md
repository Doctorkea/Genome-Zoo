# References — creature rendering research

Sources used to put together `ART_PIPELINE.md`.

Guest mood marks (heart, tear, bang, sweat, spark) use [Twemoji](https://github.com/jdecked/twemoji) PNGs (CC-BY 4.0).

Serum flasks, beakers, and bottles use [Kenney Generic Items](https://kenney.nl/assets/generic-items) (CC0). Liquid colours are re-tinted per serum.

For the full fetched Godot 4.7 / forum / skill pack used by later chats, see [`godot-context/INDEX.md`](./godot-context/INDEX.md).

## Layered "paper doll" sprite parts

- [How to layer sprites ("dress up a character") in 2D — Godot Forum](https://forum.godotengine.org/t/how-to-layer-sprites-dress-up-a-character-in-2d/11898)
- [Guide: Layered and Animated Pixel Art Outfits/Visuals for different creatures — r/godot](https://www.reddit.com/r/godot/comments/1msnvlh/guide_layered_and_animated_pixel_art/)
- [Godot docs — 2D sprite animation (Sprite2D + AnimationPlayer / AnimatedSprite2D)](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html)
- [ldev1996/sprite-customizer-2d-godot](https://github.com/ldev1996/sprite-customizer-2d-godot) — ready-made Godot 4 layered sprite customizer addon
- [lucimoon/custom-sprite-2d](https://github.com/lucimoon/custom-sprite-2d) — Godot 4 addon: layered sprites, texture swap per layer, **color modulation via grayscale textures**, AnimationPlayer sync

## Palette-swap shaders (grayscale + palette texture)

- [Creating A Simple Palette Swap Shader in Godot 4.2 (YouTube)](https://www.youtube.com/watch?v=Pp55iVPxN4Y)
- [KoBeWi/Godot-Palette-Swap-Shader](https://github.com/KoBeWi/Godot-Palette-Swap-Shader) — supports animated palettes
- [Palette Swap (no recolor / recolor) — Godot Shaders](https://godotshaders.com/shader/palette-swap-no-recolor-recolor/)
- [Palette swap shader + alpha handling discussion — r/godot](https://www.reddit.com/r/godot/comments/pjcfc0/help_with_a_palette_swap_shader_affecting_opacity/)
- [Introduction to Shaders in Godot 4 — Kodeco (luminosity/grayscale weighting)](https://www.kodeco.com/43354079-introduction-to-shaders-in-godot-4/page/2)

## Engine version — Godot 4.7

- [Godot 4.7 release announcement](https://godotengine.org/releases/4.7/)
- [Godot 4.7 changelog](https://github.com/godotengine/godot/blob/4.7-stable/CHANGELOG.md)
- [Upgrading from Godot 4.6 to Godot 4.7 (migration guide)](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)
- [Multiple resolutions — pixel-art stretch/scale settings](https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html)

## HUD, picking, pixel-art (fetched 2026-09-19)

- [Using Containers](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_containers.html)
- [GUI skinning](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_skinning.html)
- [Control (mouse_filter)](https://docs.godotengine.org/en/4.7/classes/class_control.html)
- [Viewport.physics_object_picking](https://docs.godotengine.org/en/4.7/classes/class_viewport.html)
- [CharacterBody2D (4.7)](https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html)
- [Using CharacterBody2D](https://docs.godotengine.org/en/4.7/tutorials/physics/using_character_body_2d.html)
- [Your first 2D shader](https://docs.godotengine.org/en/4.7/tutorials/shaders/your_first_shader/your_first_2d_shader.html)
- [2D sprite animation](https://docs.godotengine.org/en/4.7/tutorials/2d/2d_sprite_animation.html)
- [SubViewport](https://docs.godotengine.org/en/4.7/classes/class_subviewport.html)
- [UI elements block Area2D mouse detection](https://forum.godotengine.org/t/ui-elements-block-area2ds-mouse-detection/78150)
- [SubViewportContainer blocks mouse input](https://forum.godotengine.org/t/subviewportcontainer-blocks-mouse-input/98499)
- [Control Pass vs Ignore into SubViewport](https://forum.godotengine.org/t/confused-on-propagation-and-filtering-of-input-events-through-controls-to-subviewport/135181)
- [Area2D picking inside a SubViewport](https://forum.godotengine.org/t/area2d-not-detecting-input-event-whilst-in-subviewport/98287)
- [Pixels flickering when changing camera zoom](https://forum.godotengine.org/t/pixels-flickering-when-changing-camera-zoom/76194)
- [How to make pixel art not look weird](https://forum.godotengine.org/t/how-to-make-the-pixel-not-weird-for-pixel-game/42308)

## Agent skills / MCP

- [alexmeckes/godot-claude-skills](https://github.com/alexmeckes/godot-claude-skills)
- [alexmeckes/godot-mcp](https://github.com/alexmeckes/godot-mcp)
