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
| Place a pen | Bottom dock → Pens → pick Small / Large, then left-click a green cell. Costs cash. |
| Place an animal | Bottom dock → Animals → pick a base species, then left-click inside a pen. Costs cash. |
| Close a menu | Click anywhere outside it |
| Inspect an animal | Left-click it — an exhibit card opens on the right |
| Inspect a guest | Left-click them — a guest card opens on the right. A family shares one card |
| Send guests home | Right-click a guest, or Guest card → Send home. The whole family leaves |
| Delete an animal | Exhibit card → Delete animal |
| Inspect a pen | Left-click empty grass inside a pen (no tool selected) — a paddock card opens |
| Delete a pen | Paddock card → Delete pen. Animals inside are deleted too. No refund. |
| Edit an animal's DNA | Exhibit card → Open DNA Lab, pick a body part, drag a serum onto the empty ATGC rung |
| Check the job | Top bar → Quests. A red ! means you have a job; a gold ribbon means a reward is waiting |
| Open or close the zoo | Top bar → Open zoo / Close zoo. Starts closed. Opening needs a pen with at least one animal (an error popup says why if you don't). Closing asks first; guests then leave |
| Claim a quest | Quests → Claim reward (pays cash and/or unlocks a serum) |
| Buy a DNA vial | Top bar / lab → Vial shop, pay cash ($) for an unlocked serum |

## What's implemented

- **Grid + pen placement** — rectangular multi-cell prefabs (Small 4×3, Large 6×5 cells), ghost preview
  (green = valid, red = overlapping), snapped to a 100px grid (one cell = one 100×100 floor tile).
  `scripts/grid_service.gd`, `scripts/pen.gd`,
  `scripts/build_mode.gd`.
- **Solid fence collision** — each pen generates real `StaticBody2D` walls at runtime sized to its
  footprint; animals physically collide with them via `move_and_slide()`, not just a soft bounds check.
- **Animals** — placed inside a pen, wander to random points within it on a randomized timer, click to
  select. `scripts/animal.gd`.
- **Zoo hours** — the park starts **Closed**. Top bar → **Open zoo** once a pen has an animal;
  drop-off cars start bringing guests. **Close zoo** sends everyone home and stops new arrivals.
- **HUD** — tycoon layout: thin top plaque, **cash ($)** counter, **bottom catalog dock**
  (Pens / Animals ribbons with priced tiles, Cities: Skylines / Prison Architect style), right-side **exhibit card**
  on select (live thumbnail, archetype, who comes / who stays away and why, trait mix). Left-click a
  guest for the same style of card (who they are, what they are, likes / dislikes, and a thought
  about the zoo); families inspect
  as one group and the thumbnail camera follows the whole party.
  DNA Lab is a two-pane workbench: ATGC strand on the left, exhibit card on the right. Pick a body part,
  then drag a tag serum onto the empty base. Coat is a colour plus a surface pattern, so a Cute drop
  can turn fur into spots and a Scary drop can paint on stripes. Empty HUD space uses `MOUSE_FILTER_IGNORE` so clicks
  still reach animals.
- **Trait tags + scoring** — every part option carries 1–2 tags (`scripts/trait_library.gd`). Tag totals
  pick a skill archetype (Nimble / Tanky / Predator / Novelty / Showpiece) and two visitor-approval
  scores. Mutating a slot rescores immediately. The Coat slot has a colour and a pattern for each
  serum tag (spots, stripes, scales, slime, and so on).
- **Creature creation demo** — 5 shape slots (Body, Head, Front Legs, Back Legs, Tail). Head has
  12 options (artist set plus placeholders); other shape slots have 5. Plus a Color slot (one colour
  applied to the whole creature). Every part is a uniform **100×100**
  transparent PNG canvas (one grass cell); snout and eyes are part of the Head sprite.
- **DNA Lab + quests** — Cute serum starts unlocked with one free charge. Quests ask for real
  park progress (a fully Majestic Showpiece, a second enclosure) and pay cash plus the next serum.
- **Floor grid** — 16×10 cells of flat HSB 71/98/85 grass, with the artist's tuft sprites scattered on top.
- **Filler art** — leftover shape options are generated procedurally in
  `scripts/placeholder_art.gd` (grayscale + palette-swap, per `ART_PIPELINE.md`). Jimothy, Chimory, and
  Jimmothy override those slots with square PNGs in `art/creatures/parts/`. Chimory ($55) uses all five
  artist parts: body, gorilla head, frog arms, sheep legs, scorpion tail. Jimmothy ($20) uses all five
  artist parts: blob body, horse head, horse arm, clawed back leg, curly tail.

## What's deliberately not in this demo

Per the plan we agreed on before building:

- No save/load — everything resets when you stop running the scene.
- Only 2 pen prefabs (Small/Large) — not the full pen catalog.
- No animal-vs-animal collision — they can visually overlap each other (only pen fences block movement).
- No rotation or move — delete an animal from its exhibit card, or a pen (and everyone inside) from its paddock card. No refund.

## Known rough edges to expect

- The creature rig's part offsets (`scenes/Creature.tscn`) are eyeballed, not tuned — some shape
  combinations will look goofy. That's expected placeholder behavior, not a bug.
- Procedural shapes are intentionally simple (circles, ellipses, rects, triangles) — "doesn't have to be
  good," per the brief.

## Headless smoke test

`tests/smoke_test.gd` + `tests/smoke_test.tscn` exercise every core system (grid math, pen sizing, animal
placement, creature mutation, build mode, the cash economy, and the full HUD build including the
SubViewport thumbnail) without needing real mouse/window input. Useful for catching script errors fast
after a change, without waiting on a manual playtest. Run it from a terminal:

```
"<path to Godot_v4.7.2-stable_win64_console.exe>" --path "<project path>" --headless "res://tests/smoke_test.tscn"
```

It prints `=== SMOKE TEST PASSED ===` on success, or the exact script error and line number on failure.
It's a plain scene, not a build artifact — safe to ignore in the editor, and safe to delete once the game
outgrows it.
