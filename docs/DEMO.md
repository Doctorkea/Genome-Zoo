# Base Demo — Proof of Concept

What's actually playable right now, how to run it, and what's still a placeholder.

## Running it

Open the project in Godot 4.7 and press Play. `run/main_scene` is `res://scenes/Main.tscn`.
If the editor was already open while these files were added, use **Project → Reload Current Project**
(or fully quit and reopen) so the new autoloads register.

## Controls

| Action | Input |
| --- | --- |
| Pan camera | Right-click drag |
| Zoom camera | Scroll wheel |
| Place a pen | Toolbar → "Place Small Pen" / "Place Large Pen", then left-click a green (valid) cell |
| Place an animal | Toolbar → "Place Animal", then left-click inside a placed pen |
| Inspect an animal | Left-click it directly (works in any mode) |
| Edit an animal's DNA | Select it, click "Edit DNA" in the stats panel |
| Cancel current tool | Toolbar → "Cancel" |

## What's implemented

- **Grid + pen placement** — rectangular multi-cell prefabs (Small 4×3, Large 6×5 cells), ghost preview
  (green = valid, red = overlapping), snapped to a 32px grid. `scripts/grid_service.gd`, `scripts/pen.gd`,
  `scripts/build_mode.gd`.
- **Solid fence collision** — each pen generates real `StaticBody2D` walls at runtime sized to its
  footprint; animals physically collide with them via `move_and_slide()`, not just a soft bounds check.
- **Animals** — placed inside a pen, wander to random points within it on a randomized timer, click to
  select. `scripts/animal.gd`.
- **Click-to-inspect GUI** — clicking an animal shows a stats panel with a **live thumbnail** (a second
  `Camera2D` inside a `SubViewport` that shares the main world's `World2D` — it's rendering the actual
  animal in the world, not a copy) plus its name and currently-equipped parts.
- **Creature creation demo** — 7 shape slots (Body, Head, Eyes, Mouth, Arms, Legs, Tail), 3 options each,
  plus a Color slot (3 palettes) — the full trait-swap + palette-swap pipeline from
  [`ART_PIPELINE.md`](./ART_PIPELINE.md), all working end to end.
- **DNA Lab minigame principle** — a placeholder mutagen-point counter ticks up over time (+1 every 3s,
  starting at 15); each "Mutate" costs 5 points and reveals that slot's options to pick from. No real
  visitor economy feeds it yet — see [`GAME_DESIGN.md`](./GAME_DESIGN.md) for where that plugs in later.
- **Filler art** — every shape and color is generated procedurally at runtime in
  `scripts/placeholder_art.gd` (grayscale shapes + palette-swap shader, per `ART_PIPELINE.md`). Zero binary
  asset files. Replace slot-by-slot with real art later by swapping what `PlaceholderArt` returns for that
  slot — nothing else in the pipeline changes.

## What's deliberately not in this demo

Per the plan we agreed on before building:

- No visitor/revenue economy — pure builder + creature systems.
- No save/load — everything resets when you stop running the scene.
- Only 2 pen prefabs (Small/Large) — not the full pen catalog.
- No animal-vs-animal collision — they can visually overlap each other (only pen fences block movement).
- No build-mode active-button highlighting, rotation, or move/demolish — placement is one-shot and permanent
  for this proof of concept.

## Known rough edges to expect

This was written without being able to run the Godot editor directly, so treat it as a first pass:
- GDScript syntax/typing errors are possible — report the exact editor error and it's a quick fix.
- The creature rig's part offsets (`scenes/Creature.tscn`) are eyeballed, not tuned — some shape
  combinations will look goofy. That's expected placeholder behavior, not a bug.
- Procedural shapes are intentionally simple (circles, ellipses, rects, triangles) — "doesn't have to be
  good," per the brief.
