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
| Place a pen | Bottom dock → Pens → Small / Large, then left-click a green (valid) cell |
| Place an animal | Bottom dock → Place animal, then left-click inside a placed pen |
| Inspect an animal | Left-click it — an exhibit card opens on the right |
| Edit an animal's DNA | Exhibit card → Open DNA Lab, then pick a slot to draft three options |
| Cancel current tool | Bottom dock → Cancel, or click the active tool again |

## What's implemented

- **Grid + pen placement** — rectangular multi-cell prefabs (Small 4×3, Large 6×5 cells), ghost preview
  (green = valid, red = overlapping), snapped to a 100px grid (one cell = one 100×100 floor tile).
  `scripts/grid_service.gd`, `scripts/pen.gd`,
  `scripts/build_mode.gd`.
- **Solid fence collision** — each pen generates real `StaticBody2D` walls at runtime sized to its
  footprint; animals physically collide with them via `move_and_slide()`, not just a soft bounds check.
- **Animals** — placed inside a pen, wander to random points within it on a randomized timer, click to
  select. `scripts/animal.gd`.
- **HUD** — tycoon layout: thin top plaque + mutagen counter, **bottom build dock** (Pens / Animals),
  right-side **exhibit card** on select (live thumbnail, archetype, visitor meters, tags). DNA Lab is a
  paper workbench: pick a slot, spend 5 mutagen, choose one of three named options. Empty HUD space uses
  `MOUSE_FILTER_IGNORE` so clicks still reach animals.
- **Trait tags + scoring** — every part option carries 1–2 tags (`scripts/trait_library.gd`). Tag totals
  pick a skill archetype (Nimble / Tanky / Predator / Novelty / Showpiece) and two visitor-approval
  scores. Mutating a slot rescores immediately.
- **Creature creation demo** — 6 shape slots (Body, Head, Eyes, Front Legs, Back Legs, Tail), 3 options
  each, plus a Color slot (one colour applied to the whole creature). Every part is a uniform **100×100**
  transparent PNG canvas (one grass tile); snout is part of the Head sprite.
- **DNA Lab minigame principle** — mutagen ticks up over time (+1 every 3s, starting at 15) and sits in
  the top-right counter. Each slot draft costs 5 and reveals that slot's named 3-option cards. Slot
  buttons disable when you can't afford a draft. No real visitor economy feeds the points yet — see
  [`GAME_DESIGN.md`](./GAME_DESIGN.md) for where that plugs in later.
- **Floor grid** — 16×10 `TileMapLayer` of the artist's 100×100 grass tiles (plain grass plus scattered flower variants) so pens sit on real floor art.
- **Filler art** — every shape and color is generated procedurally at runtime in
  `scripts/placeholder_art.gd` (grayscale shapes + palette-swap shader, per `ART_PIPELINE.md`). Zero binary
  asset files. Replace slot-by-slot with real art later by swapping what `PlaceholderArt` returns for that
  slot — nothing else in the pipeline changes.

## What's deliberately not in this demo

Per the plan we agreed on before building:

- No visitor/revenue economy — tag scores are visible, but nobody walks the zoo yet.
- No save/load — everything resets when you stop running the scene.
- Only 2 pen prefabs (Small/Large) — not the full pen catalog.
- No animal-vs-animal collision — they can visually overlap each other (only pen fences block movement).
- No rotation or move/demolish — placement is one-shot and permanent for this proof of concept.

## Known rough edges to expect

- The creature rig's part offsets (`scenes/Creature.tscn`) are eyeballed, not tuned — some shape
  combinations will look goofy. That's expected placeholder behavior, not a bug.
- Procedural shapes are intentionally simple (circles, ellipses, rects, triangles) — "doesn't have to be
  good," per the brief.

## Headless smoke test

`tests/smoke_test.gd` + `tests/smoke_test.tscn` exercise every core system (grid math, pen sizing, animal
placement, creature mutation, build mode, the mutagen economy, and the full HUD build including the
SubViewport thumbnail) without needing real mouse/window input. Useful for catching script errors fast
after a change, without waiting on a manual playtest. Run it from a terminal:

```
"<path to Godot_v4.7.2-stable_win64_console.exe>" --path "<project path>" --headless "res://tests/smoke_test.tscn"
```

It prints `=== SMOKE TEST PASSED ===` on success, or the exact script error and line number on failure.
It's a plain scene, not a build artifact — safe to ignore in the editor, and safe to delete once the game
outgrows it.
