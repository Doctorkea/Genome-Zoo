---
name: godot-gui
description: Build Godot 4.7 in-game UI with Control nodes, nested Containers, Theme resources, CanvasLayer, and input that does not eat world clicks. Use when creating or changing HUD, DNA Lab, toolbars, stats panels, menus, or any Evolution Zoo GUI.
---

# Godot 4.7 GUI

Official patterns from [Using Containers](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html) and [GUI skinning](https://docs.godotengine.org/en/stable/tutorials/ui/gui_skinning.html). This is a 2D Godot game, not a web app — do not use HTML/CSS/React. For visual identity (palette, type, copy), also read `.cursor/skills/frontend-design/SKILL.md`.

## Non-negotiables

1. **UI scenes are Control-rooted.** Never make `CanvasLayer` the root of a reusable UI scene — it has no anchors. Put one `CanvasLayer` on `Main.tscn` and instance UI as children of it.
2. **Layout with nested Containers**, not hardcoded `position` / `size`. Hardcoded pixels break when the viewport is 1280×720 (100px tiles) or the window resizes.
3. **Full-rect overlays must not steal world clicks.** Set `mouse_filter = MOUSE_FILTER_IGNORE` on spacer/full-rect wrappers. Only interactive Controls (`Button`, `PanelContainer` the player clicks) use `STOP`. GUI input is processed before physics picking — a leftover full-screen Panel is why `Area2D.input_event` silently dies.
4. **Theme, don't per-node style.** Put colors/fonts/`StyleBox`es on a `Theme` resource (or one `theme` on the HUD root). Theme cascades to children. Use `add_theme_*_override` only for exceptions.
5. **Update UI from signals**, not `_process` polling. This project already has `Events.animal_selected` and `Events.mutagen_points_changed`.

## Layout recipe (HUD / panels)

```
CanvasLayer          # lives on Main, layer >= 10
└── Control          # PRESET_FULL_RECT, mouse_filter = IGNORE
    └── MarginContainer  # PRESET_FULL_RECT, IGNORE, theme margins 16
        └── VBoxContainer    # IGNORE
            ├── HBoxContainer    # top bar
            │   ├── toolbar buttons
            │   ├── Control (Expand)   # spacer, IGNORE
            │   └── stats PanelContainer
            ├── Control (Expand)       # pushes nothing; IGNORE
            └── CenterContainer        # DNA Lab
                └── lab PanelContainer
```

Size flags on a child of a Container:

- **Fill** — occupy the slot the container assigned
- **Expand** — take leftover space (spacers, stretching columns)
- **Stretch Ratio** — relative share between expanding siblings

Prefer `HBoxContainer` / `VBoxContainer` / `MarginContainer` / `PanelContainer` / `CenterContainer` / `SubViewportContainer`. Use `ScrollContainer` if the lab outgrows the viewport.

## Project scale

- Viewport: **1280×720**
- Grid / floor tile: **100×100** (`GridService.CELL_SIZE`)
- Design UI in that resolution. Do not assume 640×360 leftover positions (e.g. `Vector2(460, 12)`).

## Click-to-inspect

Animals are `CharacterBody2D` with `input_pickable = true`. `Main` enables `get_viewport().physics_object_picking`. The HUD must leave empty screen `IGNORE` so those clicks reach the animal.

## Copy

Buttons say what they do: "Place Small Pen", "Edit DNA", "Mutate (5)", "Close". Sentence case. Errors / can't-afford should say what happened, not "Error".

## Do not

- Position HUD widgets with raw `position` unless the parent is **not** a Container
- Cover the world with an invisible `Panel` (`STOP` is the default)
- Recreate web layout (flexbox, CSS grid) — use Godot Containers
- Style every `Button` individually when a Theme can do it once
